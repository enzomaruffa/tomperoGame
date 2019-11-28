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
    
    static let difficultyProbabilityDict: [GameDifficulty : [Double]] =
        [.easy: [75.0, 20.0, 5.0, 0.0],
         .medium: [10.0, 60.0, 25.0, 5.0],
         .hard: [5.0, 30.0, 40.0, 25.0]]
    
    let difficulty: GameDifficulty
    let possibleIngredients: [Ingredient]
    let playerTables: [MCPeerID:  [PlayerTable]]
    
    internal init(difficulty: GameDifficulty, possibleIngredients: [Ingredient], playerTables: [MCPeerID:  [PlayerTable]]) {
        self.difficulty = difficulty
        self.possibleIngredients = possibleIngredients
        self.playerTables  = playerTables
    }
    
    func generateOrder() -> Order {
        let maxIngredientCount = randomNumber(probabilities: GameRule.difficultyProbabilityDict[difficulty]!) + 1
        let order = Order(timeLeft: 30)
        
        var currentIngredientCount = 0

//        print("\nCurrent ingredients: \(order.ingredients)")
//        print("Current actions: \(currentActions)")
//        print("Max actions: \(maxActions)")
        
        let breadList = [SpaceshipHull(currentOwner: ""), DevilMashedBread(currentOwner: ""), Asteroid(currentOwner: "")]
        let possibleBreads = possibleIngredients.filter({ breadList.contains($0) })
        let orderBread = possibleBreads.randomElement()!
        
        order.ingredients.append(orderBread)
        
        while currentIngredientCount < maxIngredientCount {
            
//            print("Current ingredients: \(order.ingredients)")
//            print("Current actions: \(currentActions)")
//            print("Max actions: \(maxActions)")
            
            let currentPossibleIngredients = possibleIngredients.filter({ !breadList.contains($0) }).filter({ !order.ingredients.contains($0) })
            
            if currentPossibleIngredients.isEmpty {
//                print("Ingredientes esgotados")
                break
            }
            
            let newIngredient = currentPossibleIngredients.randomElement()!
            order.ingredients.append(newIngredient)
            currentIngredientCount += 1
        }
        
//        print("===exiting===")
//        print("Current ingredients: \(order.ingredients)")
//        print("Current actions: \(currentActions)")
//        print("Max actions: \(maxActions)")
        
        return order
    }
    
    func randomNumber(probabilities: [Double]) -> Int {

        // Sum of all probabilities (so that we don't have to require that the sum is 1.0):
        let sum = probabilities.reduce(0, +)
        // Random number in the range 0.0 <= rnd < sum :
        let rnd = Double.random(in: 0.0 ..< sum)
        // Find the first interval of accumulated probabilities into which `rnd` falls:
        var accum = 0.0
        for (element, probability) in probabilities.enumerated() {
            accum += probability
            if rnd < accum {
                return element
            }
        }
        // This point might be reached due to floating point inaccuracies:
        return (probabilities.count - 1)
    }
    
}
