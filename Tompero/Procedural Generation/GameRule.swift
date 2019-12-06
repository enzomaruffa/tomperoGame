//
//  GameRule.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 27/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class GameRule: Codable {
    
    //Probabilidades são na forma de "um pedido com i ações tem v[i] chance de ser gerado"
    static let difficultyProbabilityDict: [GameDifficulty : [Double]] =
        [  .easy: [0, 0.1, 0, 40, 40, 15, 4.9, 0, 0, 0, 0, 0, 0, 0, 0],
           .medium: [0, 0, 0, 10, 10, 30, 20, 20, 8, 2, 0, 0, 0, 0, 0],
           .hard: [0, 0, 0, 3, 3, 10, 10, 10, 20, 30, 10, 3.4, 0.3, 0.2, 0.1]]
    
    let difficulty: GameDifficulty
    var possibleIngredients: [Ingredient]
    let playerTables: [String: [PlayerTable]]

    var playerOrder: [String]
    
    internal init(difficulty: GameDifficulty, possibleIngredients: [Ingredient], playerTables: [String:  [PlayerTable]], playerOrder: [String]) {
        self.difficulty = difficulty
        self.possibleIngredients = possibleIngredients
        self.playerTables = playerTables
        self.playerOrder = playerOrder
    }
    
    func generateOrder() -> Order {
        // Escolhemos um número aleatório de ações
        let maxActions = randomNumber(probabilities: GameRule.difficultyProbabilityDict[difficulty]!)
        let order = Order(timeLeft: 30)

        var currentActions = 0
//
//        print("\nCurrent ingredients: \(order.ingredients)")
//        print("Current actions: \(currentActions)")
//        print("Max actions: \(maxActions)")

        // Escolhemos um pão aleatório
        let breadList = [SpaceshipHull(), DevilMashedBread(), Asteroid()]
        let possibleBreads = possibleIngredients.filter({ breadList.contains($0) })
        let orderBread = possibleBreads.randomElement()!
        currentActions += 1

        order.ingredients.append(orderBread)

        // Enquanto não atingimos nosso alvo de ações, geramos novos ingredientes
        while currentActions < maxActions {

            // Filtramos os possíveis: não é pão, não foi escolhido e não vai estourar o máximo
            let currentPossibleIngredients = possibleIngredients
                .filter({ !breadList.contains($0) })
                .filter({ !order.ingredients.contains($0) })
                .filter({ $0.numberOfActionsTilReady + currentActions <= maxActions })

            // Se esgotamos, saímos do loop
            if currentPossibleIngredients.isEmpty {
//                print("Ingredientes esgotados")
                break
            }

            // Senão, criamos um novo e adicionamos na lista se não for estourar o número de ações
            let newIngredient = currentPossibleIngredients.randomElement()!
            
            order.ingredients.append(newIngredient)
            currentActions += newIngredient.numberOfActionsTilReady
        }

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
