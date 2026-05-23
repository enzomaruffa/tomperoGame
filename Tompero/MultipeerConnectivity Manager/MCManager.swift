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

    // MARK: - Variables

    static let shared = MCManager()

    let gameName = "spacespice"

    var peerID: MCPeerID?
    var mcSession: MCSession?
    var mcAdvertiserAssistant: MCAdvertiserAssistant?

    var connectedPeers: [MCPeerID]? {
        self.mcSession?.connectedPeers ?? nil
    }

    var dataObservers: [MCManagerDataObserver] = []
    var matchmakingObservers: [MCManagerMatchmakingObserver] = []

    var hosting = false

    var selfName: String {
        (peerID?.displayName)!
    }

    // The MCPeerID must be persisted across launches. Re-instantiating a peer
    // with the same displayName on every launch produces a new identity that
    // peers fail to reconcile, which surfaces as "ghost" players and dropped
    // sessions. Apple's own guidance is to archive the MCPeerID and reload it.
    private static let peerIDDefaultsKey = "com.spacespice.mcPeerID"
    private static let peerDisplayNameDefaultsKey = "com.spacespice.mcPeerID.displayName"

    // MARK: - Initializers

    override private init() {
        super.init()
        self.peerID = MCManager.loadOrCreatePeerID()
        resetSession()
    }

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

    // Builds a globally-unique display name. iOS 16 returns the generic
    // model name (e.g. "iPhone") from UIDevice.current.name unless the app has
    // the user-assigned-device-name entitlement, so every device on the LAN
    // collides on the same MCPeerID displayName and direct sends route to the
    // wrong peer. We suffix a stable random tag so peers are always distinct.
    private static func makeStableDisplayName() -> String {
        let defaults = UserDefaults.standard
        let base = sanitize(UIDevice.current.name)

        let suffixKey = "com.spacespice.mcPeerID.suffix"
        let suffix: String
        if let existing = defaults.string(forKey: suffixKey) {
            suffix = existing
        } else {
            suffix = String(UUID().uuidString.prefix(4))
            defaults.set(suffix, forKey: suffixKey)
        }

        // MCPeerID rejects displayNames longer than 63 UTF-8 bytes; budget
        // for the " (XXXX)" suffix and truncate the base accordingly.
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
    func createNewSession(_ peerID: MCPeerID) {
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        mcSession!.delegate = self
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
        if let mcSession = self.mcSession {
            let mcBrowser = MCBrowserViewController(serviceType: "cookios", session: mcSession)
            mcBrowser.delegate = delegate
            rootViewController.present(mcBrowser, animated: true)
            self.hosting = false
        }
    }
    
    func joinSession() {
        if let mcSession = self.mcSession {
            mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "cookios", discoveryInfo: nil, session: mcSession)
            mcAdvertiserAssistant!.start()
            self.hosting = true
        }
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("\n[MCManager] Connected: \(peerID.displayName)")
        case .connecting:
            print("\n[MCManager] Connecting: \(peerID.displayName)")
        case .notConnected:
            print("\n[MCManager] Not Connected: \(peerID.displayName)")
        @unknown default:
            print("\n[MCManager] fatal error")
        }
        DispatchQueue.main.async {
            self.matchmakingObservers.forEach({ $0.playerUpdate(player: peerID.displayName, state: state) })
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            print("[MCManager] Received data")
            let wrapper = try JSONDecoder().decode(MCDataWrapper.self, from: data)
            print("[MCManager] Wrapper: \(wrapper)")
            
            if wrapper.type == .playerData {
                print("[MCManager] Sending playerData to observers: \(wrapper)")
                let peersWithStatus = try JSONDecoder().decode([MCPeerWithStatus].self, from: wrapper.object)
                matchmakingObservers.forEach({ $0.playerListSent(playersWithStatus: peersWithStatus) })
            } else if wrapper.type == .gameRule {
                print("[MCManager] Sending gameRule to observers: \(wrapper)")
                let rule = try JSONDecoder().decode(GameRule.self, from: wrapper.object)
                rule.possibleIngredients = rule.possibleIngredients.map({ $0.findDowncast() })
                matchmakingObservers.forEach({ $0.receiveGameRule(rule: rule) })
            } else {
                print("[MCManager] Sending to dataObservers: \(dataObservers)")
                dataObservers.forEach({ $0.receiveData(wrapper: wrapper) })
            }
            
        } catch let error {
            print("[MCManager] Error decoding data: \(error.localizedDescription)")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    // MARK: - Data Transfering Methods
    func sendEveryone(dataWrapper: MCDataWrapper) {
        print("[MCManager] Sending message to everyone")
        send(dataWrapper: dataWrapper, to: self.mcSession!.connectedPeers)
    }
    
    func send(dataWrapper: MCDataWrapper, to peers: [MCPeerID]) {
        do {
            let encodedData = try JSONEncoder().encode(dataWrapper)
            try self.mcSession?.send(encodedData, toPeers: peers, with: .reliable)
        } catch let error {
            print("[MCManager] Error sending data: \(error.localizedDescription)")
        }
    }
    
    func sendPeersStatus(playersWithStatus: [MCPeerWithStatus]) {
        guard !self.mcSession!.connectedPeers.isEmpty else {
            return
        }
        do {
            print("[MCManager] Sending playersWithStatus to everyone")
            let playersData = try JSONEncoder().encode(playersWithStatus)
            let dataWrapper = MCDataWrapper(object: playersData, type: .playerData)
            sendEveryone(dataWrapper: dataWrapper)
        } catch let error {
            print("[MCManager] Error sending data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Observer Methods
    
    func subscribeDataObserver(observer: MCManagerDataObserver) {
        // TODO: Add duplicate verification
        self.dataObservers.append(observer)
    }
    
    func subscribeMatchmakingObserver(observer: MCManagerMatchmakingObserver) {
        // TODO: Add duplicate verification
        self.matchmakingObservers.append(observer)
    }
    
}
