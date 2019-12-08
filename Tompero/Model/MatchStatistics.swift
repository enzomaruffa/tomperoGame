//
//  MatchStatistics.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 08/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class MatchStatistics {

    var ruleUsed: GameRule
    var totalGeneratedOrders = 0
    var totalPoints = 0
    var totalDeliveredOrders = 0
   
    internal init(ruleUsed: GameRule) {
        self.ruleUsed = ruleUsed
    }
    
}
