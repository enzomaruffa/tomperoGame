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
    
    let gameName = "cookios"
    
    var peerID: MCPeerID?
    var mcSession: MCSession?
    var mcAdvertiserAssistant: MCAdvertiserAssistant?
    
    var dataObservers: [MCManagerDataObserver] = []
    var matchmakingObservers: [MCManagerMatchmakingObserver] = []
    
    var hosting = false
    // MARK: - Initializers
    
    override private init() {
        super.init()
        let peerID = MCPeerID(displayName: UIDevice.current.name)
        self.peerID = peerID
        
        resetSession()
    }
    
    // MARK: - Session Methods
    func createNewSession(_ peerID: MCPeerID) {
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        mcSession!.delegate = self
    }
    
    func resetSession() {
        mcSession?.disconnect()
        mcSession = nil
        mcAdvertiserAssistant?.stop()
        mcAdvertiserAssistant = nil
        if let peerID = self.peerID {
            createNewSession(peerID)
        } else {
            let peerID = MCPeerID(displayName: UIDevice.current.name)
            self.peerID = peerID
            createNewSession(peerID)
        }
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
            } else if wrapper.type == .playerTableData {
                print("[MCManager] Sending playerTableData to observers: \(wrapper)")
                let tables = try JSONDecoder().decode([PlayerTable].self, from: wrapper.object)
                matchmakingObservers.forEach({ $0.receiveTableDistribution(playerTables: tables) })
            }
            else {
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
