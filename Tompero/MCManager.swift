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
    
    let shared = MCManager()
    
    let gameName = "cookios"
    
    var peerID: MCPeerID?
    var mcSession: MCSession?
    var mcAdvertiserAssistant: MCAdvertiserAssistant?
    
    var observers: [MCManagerObserver] = []
    
    // MARK: - Initializers
    
    override private init() {
        super.init()
        let peerID = MCPeerID(displayName: UIDevice.current.name) ?? MCPeerID(displayName: "(weird device with no name)")
        self.peerID = peerID
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession!.delegate = self
    }
    
    // MARK: - Methods
    
    func hostSession() {
        if let mcSession = self.mcSession {
            mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "cookios", discoveryInfo: nil, session: mcSession)
            mcAdvertiserAssistant!.start()
        }
    }
    
    func joinSession(presentingFrom rootViewController: UIViewController, delegate: MCBrowserViewControllerDelegate) {
        if let mcSession = self.mcSession {
            let mcBrowser = MCBrowserViewController(serviceType: "cookios", session: mcSession)
            mcBrowser.delegate = delegate
            rootViewController.present(mcBrowser, animated: true)
        }
    }
    
    func sendEveryone(dataWrapper: MCDataWrapper) {
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
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected: \(peerID.displayName)")
        case .connecting:
            print("Connecting: \(peerID.displayName)")
        case .notConnected:
            print("Not Connected: \(peerID.displayName)")
        @unknown default:
            print("fatal error")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let wrapper = try JSONDecoder().decode(MCDataWrapper.self, from: data)
            observers.map({ $0.receiveData(wrapper: wrapper) })
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
    
    // MARK: - Observer Methods
    
    func subscribeObserver(observer: MCManagerObserver)  {
        // TODO: Add duplicate verification
        self.observers.append(observer)
    }
    
}
