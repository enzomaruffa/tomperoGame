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
                print("[LANConnectionManager] Listener start failed: \(error)")
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
            guard let self else { return }
            let nwConnection = NWConnection(to: peer.endpoint, using: peerToPeerTCPParameters())
            let lan = LANPeerConnection(connection: nwConnection, direction: .outbound, queue: self.queue)
            lan.delegate = self
            self.pending[ObjectIdentifier(lan)] = lan
            lan.start()
            lan.sendHandshake(asHost: true)
        }
    }

    // MARK: - Sending

    func sendEveryone(dataWrapper: MCDataWrapper) {
        send(dataWrapper: dataWrapper, toDisplayName: nil)
    }

    func send(dataWrapper: MCDataWrapper, toDisplayName displayName: String?) {
        queue.async { [weak self] in
            guard let self else { return }
            let envelope = LANEnvelope(from: self.selfName, to: displayName, payload: dataWrapper)
            self.dispatchOutgoing(envelope)
        }
    }

    func sendPeersStatus(playersWithStatus: [PeerWithStatus]) {
        do {
            let data = try JSONEncoder().encode(playersWithStatus)
            let wrapper = MCDataWrapper(object: data, type: .playerData)
            sendEveryone(dataWrapper: wrapper)
        } catch {
            print("[LANConnectionManager] Encode players status failed: \(error)")
        }
    }

    /// Routes one envelope across the active connections. Star topology:
    /// - Host with target=nil: deliver to every connected joiner.
    /// - Host with target=name: deliver to that one joiner only.
    /// - Joiner: send to host; host re-routes on receipt.
    private func dispatchOutgoing(_ envelope: LANEnvelope) {
        if hosting {
            if let target = envelope.to {
                connections[target]?.sendEnvelope(envelope)
            } else {
                connections.values.forEach { $0.sendEnvelope(envelope) }
            }
        } else {
            // Single connection to host; host will re-route by `to`.
            connections.values.first?.sendEnvelope(envelope)
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
        print("[LANConnectionManager] Listener error: \(error)")
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
        print("[LANConnectionManager] Browser error: \(error)")
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
