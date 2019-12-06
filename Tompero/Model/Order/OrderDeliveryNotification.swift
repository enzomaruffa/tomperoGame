//
//  OrderDeliveryNotification.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 05/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class OrderDeliveryNotification: Codable {
    let playerName: String
    let success: Bool
    let coinsAdded: Int
    
    init(playerName: String, success: Bool, coinsAdded: Int) {
        self.playerName = playerName
        self.success = success
        self.coinsAdded = coinsAdded
    }
}
