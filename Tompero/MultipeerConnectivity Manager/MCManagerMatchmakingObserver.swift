//
//  MCManagerMatchmakingObserver.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol MCManagerMatchmakingObserver {
    
    func playerUpdate(player: String, state: MCSessionState)
    func playerListSent(playersWithStatus: [MCPeerWithStatus])
    
    func receiveTableDistribution(playerTables: [PlayerTable])
}
