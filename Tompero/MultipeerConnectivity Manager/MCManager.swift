//
//  MCManager.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import UIKit

class MCManager: NSObject, MCSessionDelegate {

    // MARK: - Constants

    static let shared = MCManager()

    let gameName = "spacespice"
    static let serviceType = "cookios"

    // MARK: - State

    private(set) var peerID: MCPeerID?
    private(set) var mcSession: MCSession?
    private var mcAdvertiserAssistant: MCAdvertiserAssistant?

    var connectedPeers: [MCPeerID]? {
        mcSession?.connectedPeers
    }

    private let dataObservers = NSHashTable<AnyObject>.weakObjects()
    private let matchmakingObservers = NSHashTable<AnyObject>.weakObjects()

    var hosting = false

    var selfName: String {
        peerID?.displayName ?? "Player"
    }

    // Serial queue for all outgoing send work so concurrent producers don't
    // race on JSONEncoder/MCSession.send. Decoded payloads are handed back to
    // observers on the main queue so consumers don't need their own dispatch.
    private let sendQueue = DispatchQueue(label: "com.spacespice.mcmanager.send")

    // MARK: - Persistent peer identity

    private static let peerIDDefaultsKey = "com.spacespice.mcPeerID"
    private static let peerDisplayNameDefaultsKey = "com.spacespice.mcPeerID.displayName"
    private static let peerSuffixDefaultsKey = "com.spacespice.mcPeerID.suffix"

    // MARK: - Initializers

    override private init() {
        super.init()
        self.peerID = MCManager.loadOrCreatePeerID()
        resetSession()
    }

    // The MCPeerID must be persisted across launches. Re-instantiating a peer
    // with the same displayName on every launch produces a new identity that
    // peers fail to reconcile, which surfaces as "ghost" players and dropped
    // sessions.
    private static func loadOrCreatePeerID() -> MCPeerID {
        let defaults = UserDefaults.standard
        let expectedDisplayName = makeStableDisplayName()

        if let data = defaults.data(forKey: peerIDDefaultsKey),
           let archived = try? NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data),
           archived.displayName == expectedDisplayName {
            return archived
        }

        let peer = MCPeerID(displayName: expectedDisplayName)
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: peer, requiringSecureCoding: true) {
            defaults.set(data, forKey: peerIDDefaultsKey)
            defaults.set(expectedDisplayName, forKey: peerDisplayNameDefaultsKey)
        }
        return peer
    }

    // iOS 16 returns the generic model name (e.g. "iPhone") from
    // UIDevice.current.name unless the app has the user-assigned-device-name
    // entitlement, so without a suffix every device on the LAN collides on the
    // same MCPeerID displayName.
    private static func makeStableDisplayName() -> String {
        let defaults = UserDefaults.standard
        let base = sanitize(UIDevice.current.name)

        let suffix: String
        if let existing = defaults.string(forKey: peerSuffixDefaultsKey) {
            suffix = existing
        } else {
            suffix = String(UUID().uuidString.prefix(4))
            defaults.set(suffix, forKey: peerSuffixDefaultsKey)
        }

        // MCPeerID rejects displayNames longer than 63 UTF-8 bytes.
        let suffixWrapped = " (\(suffix))"
        let maxBaseBytes = 63 - suffixWrapped.utf8.count
        let truncatedBase = truncate(base, toUTF8Bytes: maxBaseBytes)
        return truncatedBase + suffixWrapped
    }

    private static func sanitize(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Player" : trimmed
    }

    private static func truncate(_ string: String, toUTF8Bytes max: Int) -> String {
        guard max > 0 else { return "" }
        var result = string
        while result.utf8.count > max {
            result.removeLast()
        }
        return result
    }

    // MARK: - Session Methods

    private func createNewSession(_ peerID: MCPeerID) {
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        mcSession = session
    }

    func resetSession() {
        mcSession?.disconnect()
        mcSession = nil
        stopAdvertiser()
        let peerID = self.peerID ?? MCManager.loadOrCreatePeerID()
        self.peerID = peerID
        createNewSession(peerID)
    }

    func stopAdvertiser() {
        mcAdvertiserAssistant?.stop()
        mcAdvertiserAssistant = nil
    }

    func hostSession(presentingFrom rootViewController: UIViewController, delegate: MCBrowserViewControllerDelegate) {
        guard let mcSession else { return }
        let mcBrowser = MCBrowserViewController(serviceType: MCManager.serviceType, session: mcSession)
        mcBrowser.delegate = delegate
        rootViewController.present(mcBrowser, animated: true)
        hosting = false
    }

    func joinSession() {
        guard let mcSession else { return }
        let assistant = MCAdvertiserAssistant(serviceType: MCManager.serviceType, discoveryInfo: nil, session: mcSession)
        assistant.start()
        mcAdvertiserAssistant = assistant
        hosting = true
    }

    // MARK: - Peer lookup

    /// Returns the connected MCPeerID matching the given display name, or nil.
    /// Use this instead of force-unwrapping a filtered array — peers can
    /// disconnect between when the UI captures their name and when the send
    /// fires.
    func connectedPeer(named name: String) -> MCPeerID? {
        mcSession?.connectedPeers.first(where: { $0.displayName == name })
    }

    // MARK: - MCSessionDelegate

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("[MCManager] Connected: \(peerID.displayName)")
        case .connecting:
            print("[MCManager] Connecting: \(peerID.displayName)")
        case .notConnected:
            print("[MCManager] Not Connected: \(peerID.displayName)")
        @unknown default:
            print("[MCManager] Unknown peer state")
        }
        DispatchQueue.main.async { [weak self] in
            self?.matchmakingObserversSnapshot.forEach { $0.playerUpdate(player: peerID.displayName, state: state) }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let decoder = JSONDecoder()
        do {
            let wrapper = try decoder.decode(MCDataWrapper.self, from: data)
            switch wrapper.type {
            case .playerData:
                let peersWithStatus = try decoder.decode([MCPeerWithStatus].self, from: wrapper.object)
                DispatchQueue.main.async { [weak self] in
                    self?.matchmakingObserversSnapshot.forEach { $0.playerListSent(playersWithStatus: peersWithStatus) }
                }
            case .gameRule:
                let rule = try decoder.decode(GameRule.self, from: wrapper.object)
                rule.possibleIngredients = rule.possibleIngredients.map { $0.findDowncast() }
                DispatchQueue.main.async { [weak self] in
                    self?.matchmakingObserversSnapshot.forEach { $0.receiveGameRule(rule: rule) }
                }
            default:
                DispatchQueue.main.async { [weak self] in
                    self?.dataObserversSnapshot.forEach { $0.receiveData(wrapper: wrapper) }
                }
            }
        } catch {
            print("[MCManager] Error decoding data: \(error.localizedDescription)")
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}

    // MARK: - Data Transfering Methods

    func sendEveryone(dataWrapper: MCDataWrapper) {
        guard let peers = mcSession?.connectedPeers, !peers.isEmpty else { return }
        send(dataWrapper: dataWrapper, to: peers)
    }

    func send(dataWrapper: MCDataWrapper, to peers: [MCPeerID]) {
        guard !peers.isEmpty, let session = mcSession else { return }
        sendQueue.async {
            do {
                let encodedData = try JSONEncoder().encode(dataWrapper)
                try session.send(encodedData, toPeers: peers, with: .reliable)
            } catch {
                print("[MCManager] Error sending data: \(error.localizedDescription)")
            }
        }
    }

    func sendPeersStatus(playersWithStatus: [MCPeerWithStatus]) {
        guard let peers = mcSession?.connectedPeers, !peers.isEmpty else { return }
        do {
            let playersData = try JSONEncoder().encode(playersWithStatus)
            let dataWrapper = MCDataWrapper(object: playersData, type: .playerData)
            send(dataWrapper: dataWrapper, to: peers)
        } catch {
            print("[MCManager] Error encoding players status: \(error.localizedDescription)")
        }
    }

    // MARK: - Observer Methods

    func subscribeDataObserver(observer: MCManagerDataObserver) {
        dataObservers.add(observer as AnyObject)
    }

    func unsubscribeDataObserver(observer: MCManagerDataObserver) {
        dataObservers.remove(observer as AnyObject)
    }

    func subscribeMatchmakingObserver(observer: MCManagerMatchmakingObserver) {
        matchmakingObservers.add(observer as AnyObject)
    }

    func unsubscribeMatchmakingObserver(observer: MCManagerMatchmakingObserver) {
        matchmakingObservers.remove(observer as AnyObject)
    }

    private var dataObserversSnapshot: [MCManagerDataObserver] {
        dataObservers.allObjects.compactMap { $0 as? MCManagerDataObserver }
    }

    private var matchmakingObserversSnapshot: [MCManagerMatchmakingObserver] {
        matchmakingObservers.allObjects.compactMap { $0 as? MCManagerMatchmakingObserver }
    }
}
