//
//  LANConnectionManager.swift
//  Tompero
//

import Foundation
import Network
import UIKit

/// Replaces `MCManager`. Owns the listener, the browser, and one
/// `LANPeerConnection` per remote peer. Star topology: the host is the
/// central hub, joiners only hold a single connection to the host, and the
/// host relays direct sends between joiners.
///
/// Public surface intentionally mirrors the shape `GameConnectionManager` and
/// the view controllers already use against `MCManager` so the rest of the
/// app is largely untouched by the transport swap.
final class LANConnectionManager: NSObject {

    // MARK: - Singleton

    static let shared = LANConnectionManager()

    // MARK: - Public state

    /// True when this device acts as the match host (runs the browser, dials
    /// joiners, relays envelopes).
    var hosting = false

    /// Local display name (Bonjour service name + lobby label).
    var selfName: String { LocalPeerIdentity.current.displayName }

    /// Display names of currently-connected remote peers.
    var connectedDisplayNames: [String] {
        queue.sync { connections.values.compactMap { $0.state == .connected ? $0.remoteIdentity?.displayName : nil } }
    }

    // MARK: - Internals

    /// Single serial queue everything network-related funnels through, so we
    /// never touch `connections` from two threads. Observers are dispatched
    /// on main from this queue.
    private let queue = DispatchQueue(label: "com.spacespice.lan.manager")

    private let listener: LANListener
    private let browser: LANBrowser

    /// Active connections keyed by the remote display name once handshake
    /// completes. Pre-handshake connections live in `pending` until we know
    /// who they are.
    private var connections: [String: LANPeerConnection] = [:]
    private var pending: [ObjectIdentifier: LANPeerConnection] = [:]

    /// Most recent set of peers the browser has surfaced. Exposed to the
    /// picker UI via `discoveredPeers`.
    private var discovered: [LANBrowser.DiscoveredPeer] = []

    /// Endpoints we've dialed so we can re-dial after a transient drop.
    /// Keyed by display name (the routing key the rest of the app uses).
    private var dialledEndpoints: [String: NWEndpoint] = [:]

    /// Per-peer reconnect backoff state. Reset on a successful re-handshake.
    private var reconnectPolicies: [String: LANReconnectPolicy] = [:]

    /// Direct sends to a currently-disconnected peer are queued here so
    /// reconnect can replay them. Capped per peer to avoid unbounded growth.
    private static let sendBufferCapacity = 32
    private var pendingSends: [String: [LANEnvelope]] = [:]

    /// True while the app is backgrounded — we stop advertising/browsing and
    /// pause reconnect attempts (iOS would block them anyway), then resume
    /// on `didBecomeActive`.
    private var isBackgrounded = false

    private let dataObservers = NSHashTable<AnyObject>.weakObjects()
    private let matchmakingObservers = NSHashTable<AnyObject>.weakObjects()
    private weak var discoveryObserver: LANDiscoveryObserver?

    // MARK: - Init

    override private init() {
        let me = LocalPeerIdentity.current
        let q = DispatchQueue(label: "com.spacespice.lan.manager")
        listener = LANListener(displayName: me.displayName, queue: q)
        browser = LANBrowser(queue: q)
        super.init()
        listener.delegate = self
        browser.delegate = self
        registerLifecycleObservers()
    }

    private func registerLifecycleObservers() {
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func applicationWillResignActive() {
        queue.async { [weak self] in
            guard let self else { return }
            self.isBackgrounded = true
            // iOS will pause our connections; stop the discovery surfaces so
            // we don't sit advertising into the void.
            self.listener.stop()
            self.browser.stop()
        }
    }

    @objc private func applicationDidBecomeActive() {
        queue.async { [weak self] in
            guard let self else { return }
            self.isBackgrounded = false
            // Restart the appropriate discovery surface for our role.
            if self.hosting {
                self.browser.start()
            } else {
                try? self.listener.start()
            }
            // Anything that didn't survive the background will surface as a
            // disconnect callback and trigger the reconnect path. Kick the
            // joiner side proactively by re-dialing every endpoint we know,
            // since the listener-only joiner needs the host to find it again.
            self.attemptKnownReconnects()
        }
    }

    private func attemptKnownReconnects() {
        for (name, endpoint) in dialledEndpoints where connections[name] == nil {
            dialEndpoint(endpoint, expectedName: name)
        }
    }

    // MARK: - Session lifecycle

    /// Tear down all connections and stop advertising/browsing. Called when
    /// returning to the menu so a fresh match starts clean.
    func resetSession() {
        queue.async { [weak self] in
            guard let self else { return }
            self.connections.values.forEach { $0.cancel() }
            self.connections.removeAll()
            self.pending.values.forEach { $0.cancel() }
            self.pending.removeAll()
            self.discovered.removeAll()
            self.dialledEndpoints.removeAll()
            self.reconnectPolicies.removeAll()
            self.pendingSends.removeAll()
            self.listener.stop()
            self.browser.stop()
            self.hosting = false
        }
    }

    /// Host enters the waiting room. Starts the browser so the host can see
    /// joiners' Bonjour services. Does not yet open the picker UI.
    func startHosting() {
        hosting = true
        queue.async { [weak self] in
            self?.browser.start()
        }
    }

    /// Joiner enters the waiting room. Starts advertising via Bonjour so the
    /// host's browser can find us.
    func startJoining() {
        hosting = false
        queue.async { [weak self] in
            guard let self else { return }
            do {
                try self.listener.start()
            } catch {
            }
        }
    }

    /// Stop advertising. Joiners call this once a game rule arrives so they
    /// don't keep showing up in other hosts' browsers.
    func stopAdvertising() {
        queue.async { [weak self] in
            self?.listener.stop()
        }
    }

    // MARK: - Discovery (host side)

    /// Snapshot of peers currently visible to the host's browser, filtered to
    /// those we haven't already connected to. Used by the picker UI.
    var discoveredPeers: [LANBrowser.DiscoveredPeer] {
        queue.sync {
            discovered.filter { peer in
                connections[peer.displayName] == nil
            }
        }
    }

    func setDiscoveryObserver(_ observer: LANDiscoveryObserver?) {
        discoveryObserver = observer
    }

    /// Host picked a peer in the picker — dial them.
    func invite(_ peer: LANBrowser.DiscoveredPeer) {
        queue.async { [weak self] in
            self?.dialEndpoint(peer.endpoint, expectedName: peer.displayName)
        }
    }

    /// Open an outbound connection. Used both for the initial invite and for
    /// reconnect attempts after a drop.
    private func dialEndpoint(_ endpoint: NWEndpoint, expectedName: String?) {
        if let expectedName {
            dialledEndpoints[expectedName] = endpoint
        }
        let nwConnection = NWConnection(to: endpoint, using: peerToPeerTCPParameters())
        let lan = LANPeerConnection(connection: nwConnection, direction: .outbound, queue: queue, remoteEndpoint: endpoint)
        lan.delegate = self
        pending[ObjectIdentifier(lan)] = lan
        lan.start()
        lan.sendHandshake(asHost: hosting)
    }

    private func scheduleReconnect(for name: String) {
        guard !isBackgrounded else { return }
        guard let endpoint = dialledEndpoints[name] else { return }

        var policy = reconnectPolicies[name] ?? .default
        guard let delay = policy.next() else {
            Log.network.warning("Reconnect to \(name, privacy: .public) gave up after exhausting policy")
            dialledEndpoints.removeValue(forKey: name)
            reconnectPolicies.removeValue(forKey: name)
            pendingSends.removeValue(forKey: name)
            return
        }
        reconnectPolicies[name] = policy

        Log.network.info("Reconnecting to \(name, privacy: .public) in \(delay)s")
        queue.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            guard self.connections[name] == nil else { return }
            self.dialEndpoint(endpoint, expectedName: name)
        }
    }

    private func bufferSendIfDirected(_ envelope: LANEnvelope) {
        // Broadcasts get dropped during disconnect (state-update messages
        // typically supersede prior ones; replaying stale broadcasts costs
        // memory for no gain). Direct sends get buffered.
        guard let target = envelope.to, target != selfName else { return }
        var buffer = pendingSends[target] ?? []
        buffer.append(envelope)
        if buffer.count > LANConnectionManager.sendBufferCapacity {
            buffer.removeFirst(buffer.count - LANConnectionManager.sendBufferCapacity)
        }
        pendingSends[target] = buffer
    }

    private func flushPendingSends(to name: String) {
        guard let buffer = pendingSends.removeValue(forKey: name) else { return }
        guard let connection = connections[name] else { return }
        for envelope in buffer {
            connection.sendEnvelope(envelope)
        }
    }

    // MARK: - Sending

    func sendEveryone(dataWrapper: WirePayload) {
        send(dataWrapper: dataWrapper, toDisplayName: nil)
    }

    func send(dataWrapper: WirePayload, toDisplayName displayName: String?) {
        queue.async { [weak self] in
            guard let self else { return }
            let envelope = LANEnvelope(from: self.selfName, to: displayName, payload: dataWrapper)
            self.dispatchOutgoing(envelope)
        }
    }

    func sendPeersStatus(playersWithStatus: [PeerWithStatus]) {
        do {
            let data = try JSONEncoder().encode(playersWithStatus)
            let wrapper = WirePayload(object: data, type: .playerData)
            sendEveryone(dataWrapper: wrapper)
        } catch {
            Log.network.error("Encode players status failed: \(String(describing: error), privacy: .public)")
        }
    }

    /// Routes one envelope across the active connections. Star topology:
    /// - Host with target=nil: deliver to every connected joiner.
    /// - Host with target=name: deliver to that one joiner only.
    /// - Joiner: send to host; host re-routes on receipt.
    private func dispatchOutgoing(_ envelope: LANEnvelope) {
        if hosting {
            if let target = envelope.to {
                if let connection = connections[target] {
                    connection.sendEnvelope(envelope)
                } else {
                    bufferSendIfDirected(envelope)
                }
            } else {
                connections.values.forEach { $0.sendEnvelope(envelope) }
            }
        } else {
            if let connection = connections.values.first {
                connection.sendEnvelope(envelope)
            } else {
                bufferSendIfDirected(envelope)
            }
        }
    }

    // MARK: - Observers

    func subscribeDataObserver(observer: LANDataObserver) {
        dataObservers.add(observer as AnyObject)
    }

    func unsubscribeDataObserver(observer: LANDataObserver) {
        dataObservers.remove(observer as AnyObject)
    }

    func subscribeMatchmakingObserver(observer: LANMatchmakingObserver) {
        matchmakingObservers.add(observer as AnyObject)
    }

    func unsubscribeMatchmakingObserver(observer: LANMatchmakingObserver) {
        matchmakingObservers.remove(observer as AnyObject)
    }

    private var dataObserversSnapshot: [LANDataObserver] {
        dataObservers.allObjects.compactMap { $0 as? LANDataObserver }
    }

    private var matchmakingObserversSnapshot: [LANMatchmakingObserver] {
        matchmakingObservers.allObjects.compactMap { $0 as? LANMatchmakingObserver }
    }

    // MARK: - Incoming routing

    private func handleIncoming(_ envelope: LANEnvelope, from connection: LANPeerConnection) {
        // Host duty: if the envelope has a recipient that isn't us, forward.
        // If it's a broadcast, fan out to all OTHER joiners and also dispatch
        // locally to our own observers.
        if hosting {
            if let target = envelope.to {
                if target == selfName {
                    dispatchLocally(envelope)
                } else {
                    connections[target]?.sendEnvelope(envelope)
                }
            } else {
                for (name, peer) in connections where name != envelope.from {
                    peer.sendEnvelope(envelope)
                }
                dispatchLocally(envelope)
            }
        } else {
            // Joiner: trust host's routing — anything that arrives is for us.
            dispatchLocally(envelope)
        }
    }

    private func dispatchLocally(_ envelope: LANEnvelope) {
        let wrapper = envelope.payload
        let matchmakingObservers = matchmakingObserversSnapshot
        let dataObservers = dataObserversSnapshot

        switch wrapper.type {
        case .playerData:
            guard let peers = try? JSONDecoder().decode([PeerWithStatus].self, from: wrapper.object) else { return }
            DispatchQueue.main.async {
                matchmakingObservers.forEach { $0.playerListSent(playersWithStatus: peers) }
            }
        case .gameRule:
            guard let rule = try? JSONDecoder().decode(GameRule.self, from: wrapper.object) else { return }
            rule.possibleIngredients = rule.possibleIngredients.map { $0.findDowncast() }
            DispatchQueue.main.async {
                matchmakingObservers.forEach { $0.receiveGameRule(rule: rule) }
            }
        default:
            DispatchQueue.main.async {
                dataObservers.forEach { $0.receiveData(wrapper: wrapper) }
            }
        }
    }
}

// MARK: - Listener / browser delegates

extension LANConnectionManager: LANListenerDelegate {
    func listenerDidBecomeReady(_ listener: LANListener) {
        // No-op; we only act on incoming connections.
    }

    func listener(_ listener: LANListener, didAccept connection: NWConnection) {
        let lan = LANPeerConnection(connection: connection, direction: .inbound, queue: queue)
        lan.delegate = self
        pending[ObjectIdentifier(lan)] = lan
        lan.start()
        lan.sendHandshake(asHost: hosting)
    }

    func listener(_ listener: LANListener, didFailWithError error: Error) {
        Log.network.error("Listener error: \(String(describing: error), privacy: .public)")
    }
}

extension LANConnectionManager: LANBrowserDelegate {
    func browser(_ browser: LANBrowser, didUpdate peers: [LANBrowser.DiscoveredPeer]) {
        discovered = peers
        let snapshot = discoveredPeers
        let observer = discoveryObserver
        DispatchQueue.main.async {
            observer?.discoveryDidUpdate(peers: snapshot)
        }
    }

    func browser(_ browser: LANBrowser, didFailWithError error: Error) {
        Log.network.error("Browser error: \(String(describing: error), privacy: .public)")
    }
}

// MARK: - Per-connection callbacks

extension LANConnectionManager: LANPeerConnectionDelegate {

    func peerConnection(_ connection: LANPeerConnection, didChangeState state: PeerConnectionState) {
        guard let name = connection.remoteIdentity?.displayName else { return }
        let observers = matchmakingObserversSnapshot
        DispatchQueue.main.async {
            observers.forEach { $0.playerUpdate(player: name, state: state) }
        }
    }

    func peerConnection(_ connection: LANPeerConnection, didCompleteHandshake handshake: LANHandshake) {
        let name = handshake.peer.displayName
        pending.removeValue(forKey: ObjectIdentifier(connection))
        // If we already had a connection to this peer (stale reconnect),
        // cancel the old one — newest wins.
        if let existing = connections[name], existing !== connection {
            existing.cancel()
        }
        connections[name] = connection

        // Successful handshake — reset backoff and replay anything we buffered
        // while the peer was offline.
        reconnectPolicies[name]?.reset()
        flushPendingSends(to: name)

        let observers = matchmakingObserversSnapshot
        DispatchQueue.main.async {
            observers.forEach { $0.playerUpdate(player: name, state: .connected) }
        }
    }

    func peerConnection(_ connection: LANPeerConnection, didReceive envelope: LANEnvelope) {
        handleIncoming(envelope, from: connection)
    }

    func peerConnection(_ connection: LANPeerConnection, didDisconnectWithError error: Error?) {
        pending.removeValue(forKey: ObjectIdentifier(connection))
        let name = connection.remoteIdentity?.displayName
        if let name, connections[name] === connection {
            connections.removeValue(forKey: name)
        }
        if let name {
            let observers = matchmakingObserversSnapshot
            DispatchQueue.main.async {
                observers.forEach { $0.playerUpdate(player: name, state: .notConnected) }
            }
            // If this was an outbound connection (we know the endpoint),
            // attempt to re-establish.
            if dialledEndpoints[name] != nil {
                scheduleReconnect(for: name)
            }
        }
    }
}

// MARK: - Observers for discovered peer list (used by the picker UI)

protocol LANDiscoveryObserver: AnyObject {
    func discoveryDidUpdate(peers: [LANBrowser.DiscoveredPeer])
}

// MARK: - Helpers

private func peerToPeerTCPParameters() -> NWParameters {
    let parameters = NWParameters.tcp
    parameters.includePeerToPeer = true
    return parameters
}
