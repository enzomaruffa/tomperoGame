//
//  RulesFactory.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 27/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class GameRuleFactory {
    
    static let difficultyActionsDict: [GameDifficulty : Int] = [.easy : 5, .medium : 5, .hard :9]
    
    static func generateRule(difficulty: GameDifficulty, players: [MCPeerID]) {
        
        let totalPlayers = players.count
        let spacePerPlayer = 3
        
        var occupiedSpaces = 0
        let maxSpaces = totalPlayers * spacePerPlayer
        
        var totalActions = 0
        let targetActionCount = difficultyActionsDict[difficulty]
        
        // Instancia as mesas dos jogadores
        var playerTables: [MCPeerID: [PlayerTable]]
        for player in players {
            playerTables[player] = Array(repeating: PlayerTable(), count: spacePerPlayer)
        }
        
        
        var currentIngredients: [Ingredient.Type] = []
        
        let firstIngredient = [SpaceshipHull(currentOwner: ""), DevilMashedBread(currentOwner: ""), Asteroid(currentOwner: "")].randomElement()!
        
        totalActions += firstIngredient.numberOfActionsTilReady
        occupiedSpaces += 1
        
        currentIngredients.append(type(of: firstIngredient))
        
        //Add plate
        occupiedSpaces += 1
        
        var possibleIngredients: [Ingredient] = [Broccoli(currentOwner: ""), Eyes(currentOwner: ""), Horn(currentOwner: ""), MarsSand(currentOwner: ""), MoonCheese(currentOwner: ""), SaturnOnionRings(currentOwner: ""), Tardigrades(currentOwner: ""), Tentacle(currentOwner: "")]
        
        GameRule(difficulty: difficulty, possibleIngredients: <#T##[Ingredient.Type]#>, averageActions: targetActionCount, playerTables: <#T##[MCPeerID : [PlayerTable]]#>)
        
        
        
    }
    
}
