//
//  GameRule.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 27/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class GameRule {
    
    let difficulty: GameDifficulty
    let possibleIngredients: [Ingredient.Type]
    let averageActions: Int
    let playerTables: [MCPeerID:  [PlayerTable]]
    
    internal init(difficulty: GameDifficulty, possibleIngredients: [Ingredient.Type], averageActions: Int, playerTables: [MCPeerID:  [PlayerTable]]) {
        self.difficulty = difficulty
        self.possibleIngredients = possibleIngredients
        self.averageActions = averageActions
        self.playerTables  = playerTables
    }
    
}
