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
    
    static let difficultyActionsDict: [GameDifficulty : Int] = [.easy: 4, .medium: 6, .hard: 8]
    
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
    
    func generateOrder() -> Order {
        let maxActions = GameRule.difficultyActionsDict[difficulty]!
        let order = Order(timeLeft: 30)
        
        var currentActions = 0

        print("\nCurrent ingredients: \(order.ingredients)")
        print("Current actions: \(currentActions)")
        print("Max actions: \(maxActions)")
        
        let breadList = [SpaceshipHull(currentOwner: ""), DevilMashedBread(currentOwner: ""), Asteroid(currentOwner: "")]
        let possibleBreads = possibleIngredients.filter({ breadList.contains($0) })
        let orderBread = possibleBreads.randomElement()!
        currentActions += 1
        
        order.ingredients.append(orderBread)
        
        while currentActions < maxActions {
            
            print("Current ingredients: \(order.ingredients)")
            print("Current actions: \(currentActions)")
            print("Max actions: \(maxActions)")
            
            let currentPossibleIngredients = possibleIngredients.filter({ !breadList.contains($0) }).filter({ !order.ingredients.contains($0) })
            
            if currentPossibleIngredients.isEmpty {
                print("Ingredientes esgotados")
                break
            }
            
            let newIngredient = currentPossibleIngredients.randomElement()!
            order.ingredients.append(newIngredient)
            currentActions += newIngredient.numberOfActionsTilReady
        }
        
        print("===exiting===")
        print("Current ingredients: \(order.ingredients)")
        print("Current actions: \(currentActions)")
        print("Max actions: \(maxActions)")
        
        return order
    }
    
}
