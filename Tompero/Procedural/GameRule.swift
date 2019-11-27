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
    
    static let difficultyActionsDict: [GameDifficulty : Int] = [.easy: 5, .medium: 5, .hard: 9]
    
    let difficulty: GameDifficulty
    let possibleIngredients: [Ingredient]
    var averageActions: Int {
        GameRule.difficultyActionsDict[self.difficulty]!
    }
    let playerTables: [MCPeerID:  [PlayerTable]]
    
    internal init(difficulty: GameDifficulty, possibleIngredients: [Ingredient], playerTables: [MCPeerID:  [PlayerTable]]) {
        self.difficulty = difficulty
        self.possibleIngredients = possibleIngredients
        self.playerTables  = playerTables
    }
    
}
