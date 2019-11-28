//
//  MCPeerWithStatus.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 28/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class MCPeerWithStatus: Codable, Equatable {
    
    var name: String
    var status: MCSessionState
    
    internal init(peer: String, status: MCSessionState) {
        self.name = peer
        self.status = status
    }
    
    static func == (lhs: MCPeerWithStatus, rhs: MCPeerWithStatus) -> Bool {
        lhs.name == rhs.name && lhs.status == rhs.status
    }
    func copy() -> MCPeerWithStatus {
        return MCPeerWithStatus(peer: self.name, status: self.status)
    }
    
}

extension MCSessionState: Codable {
    
}
