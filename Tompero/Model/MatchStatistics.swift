//
//  MatchStatistics.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 08/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class MatchStatistics: Codable {

    var ruleUsed: GameRule
    var totalGeneratedOrders = 0
    var totalPoints = 0
    var totalDeliveredOrders = 0
    
    var matchHash: String {
        // hash is based on match results, player order, difficulty, tables, year, month and date
        var stringToBeHashed = "\(totalGeneratedOrders).\(totalPoints).\(totalDeliveredOrders)"
        stringToBeHashed += ruleUsed.playerOrder.joined()
        stringToBeHashed += ruleUsed.difficulty.rawValue
        stringToBeHashed += ruleUsed.playerTables.keys.sorted().map {
            ruleUsed.playerTables[$0]!.map {
                $0.type.rawValue
            }.joined()
        }.joined()
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        stringToBeHashed += dateFormatter.string(from: Date())
        
        return stringToBeHashed.md5Value
    }
   
    internal init(ruleUsed: GameRule) {
        self.ruleUsed = ruleUsed
    }
    
}
