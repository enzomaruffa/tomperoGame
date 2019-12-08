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
    
    static func generateRule(difficulty: GameDifficulty, players: [String]) -> GameRule {
        
        //        print("Creating control variables")
        // Variáveis de controle
        let totalPlayers = players.filter({ $0 != "__empty__" }).count
        let spacePerPlayer = 3
        
        var occupiedSpaces = 0
        let maxSpaces = totalPlayers * spacePerPlayer
        
        //        print("Creating players tables")
        // Instancia as mesas dos jogadores
        var playerTables: [String: [PlayerTable]] = [:]
        for player in players.filter({ $0 != "__empty__" }) {
            playerTables[player] = []
            for _ in 0..<spacePerPlayer {
                playerTables[player]!.append(PlayerTable())
            }
        }
        
        //        print("Creating current ingredients")
        // Lista de ingredientes atuais
        var currentIngredients: [Ingredient] = []
        
        //        print("Generating first ingredient")
        // Gera o primeiro ingrediente aleatório
//        var breadList = [SpaceshipHull(), DevilMashedBread(), Asteroid()]
        var breadList = [Asteroid()]
        let firstIngredient = breadList.randomElement()!
        breadList.removeAll(where: {$0 == firstIngredient})
        
        // Incrementa variaveis
        occupiedSpaces += 1
        
        // Adiciona na lista de ingredientes
        currentIngredients.append(firstIngredient)
        
        //        print("Adding ingredient to random player")
        // Adiciona o ingrediente na mesa de um jogador aleatório
        var randomPlayer = playerTables.keys.randomElement()!
        var randomTable = playerTables[randomPlayer]?.randomElement()!
        randomTable?.type = .ingredient
        randomTable?.ingredient = firstIngredient
        
        //        print("Adding plate to random player")
        //Adiciona um prato
        occupiedSpaces += 1
        
        // Pega só as mesas vazias. Filtra pelos jogadores e depois pelas mesas que possuem espaço vazio
        var playerWithEmptyTablesList = playerTables.keys.filter({ (playerTables[$0]?.contains(where: {$0.type == .empty}))! })
        randomPlayer = playerWithEmptyTablesList.randomElement()!
        randomTable = playerTables[randomPlayer]?.filter({ $0.type == .empty }).randomElement()!
        randomTable?.type = .plate
        
        // Ingredientes possíveis ainda:
//        var possibleIngredients: [Ingredient] = [Broccoli(), Eyes(), Horn(), MarsSand(), MoonCheese(), SaturnOnionRings(), Tardigrades(), Tentacle()]
        var possibleIngredients: [Ingredient] = [Tentacle(), Eyes(), MoonCheese(), Tardigrades()]
        
        var actionsList: [Component.Type] = []
        
        //        print("Starting core loop")
        while occupiedSpaces < maxSpaces {
            // Escolhe um novo ingrediente
            guard let newIngredient = possibleIngredients.randomElement() else {
                break
            }
            
            possibleIngredients.removeAll(where: {$0 == newIngredient})
            
            // Se tem poucos, adiciona mais pães
            if possibleIngredients.count < 5 {
                //                print("Adding breads")
                possibleIngredients += breadList
                breadList = []
            }
            
            // Verifica quantos espaços precisa pra ele:
            var supposedSpaces = 1
            
            for component in newIngredient.components {
                let componentType = type(of: component)
                if !actionsList.contains(where: { $0 == componentType}) {
                    supposedSpaces += 1
                }
            }
            
            //            print("occupiedSpaces \(occupiedSpaces) + supposedSpaces = \(supposedSpaces) < maxSpaces \(maxSpaces)?")
            // Não ultrapassa o limite de espaços
            guard occupiedSpaces + supposedSpaces <= maxSpaces else {
                continue
            }
            
            //            print("Adding ingredient")
            // Adiciona o ingrediente na lista
            occupiedSpaces += 1
            let playerWithEmptyTablesList = playerTables.keys.filter({ (playerTables[$0]?.contains(where: {$0.type == .empty}))! })
            randomPlayer = playerWithEmptyTablesList.randomElement()!
            randomTable = playerTables[randomPlayer]?.filter({ $0.type == .empty }).randomElement()!
            randomTable?.type = .ingredient
            randomTable?.ingredient = newIngredient
            
            currentIngredients.append(newIngredient)
            
            // Se a ação dele ainda não existe, adiciona as ações na lista. Também adiciona bancada
            for component in newIngredient.components {
                
                let componentType = type(of: component)
                
                if !actionsList.contains(where: { $0 == componentType}) {
                    actionsList.append(componentType)
                    
                    // Adiciona na mesa de um jogador aleatório
                    occupiedSpaces += 1
                    let playerWithEmptyTablesList = playerTables.keys.filter({ (playerTables[$0]?.contains(where: {$0.type == .empty}))! })
                    randomPlayer = playerWithEmptyTablesList.randomElement()!
                    randomTable = playerTables[randomPlayer]?.filter({ $0.type == .empty }).randomElement()!
                    randomTable?.type = componentToPlayerType(type: component)!
                    
                    // Se o ação já existe, pode ou não adicionar mais uma mesa que faz aquilo.
                } else if Int.random(in: 0...100) < 70 && occupiedSpaces + 1 < maxSpaces { // 70% de chance de adicionar novamente
                    
                    // Adiciona a ação novamente
                    occupiedSpaces += 1
                    let playerWithEmptyTablesList = playerTables.keys.filter({ (playerTables[$0]?.contains(where: {$0.type == .empty}))! })
                    randomPlayer = playerWithEmptyTablesList.randomElement()!
                    randomTable = playerTables[randomPlayer]?.filter({ $0.type == .empty }).randomElement()!
                    randomTable?.type = componentToPlayerType(type: component)!
                }
            }
        }
        
        // Verificações adicionais
        // Check user with empty spaces
        playerWithEmptyTablesList = playerTables.keys.filter({ (playerTables[$0]?.contains(where: {$0.type == .empty}) ?? false) })
        while !playerWithEmptyTablesList.isEmpty {
            let randomPlayerWithEmpty = playerWithEmptyTablesList.randomElement()!
            print("\(randomPlayerWithEmpty) has an empty space!")

            // List of those with something
            let playersWithSomethingList = playerTables.keys.filter({ !(playerTables[$0]?.contains(where: {$0.type == .empty}) ?? true) })
            
            // Random player with something
            let randomPlayerWithSomething = playersWithSomethingList.randomElement()!
            
            // Random table type from the player that has something
            let randomTableToCopy = playerTables[randomPlayerWithSomething]!.filter({$0.type != .empty}).randomElement()!
            
            // Setting it in the player that has an empty space
            randomTable = playerTables[randomPlayerWithEmpty]?.filter({ $0.type == .empty }).randomElement()!
            randomTable?.type = randomTableToCopy.type
            
            if randomTableToCopy.type == .ingredient {
                randomTable?.ingredient = randomTableToCopy.ingredient
            }
            
            print("Filled with \(randomTableToCopy.type)")
            
            // repeating search
            playerWithEmptyTablesList = playerTables.keys.filter({ (playerTables[$0]?.contains(where: {$0.type == .empty}) ?? false) })
        }
        
        // Check user with 3 ingredients
        
        // Check user with no ingredients
        
        return GameRule(difficulty: difficulty, possibleIngredients: currentIngredients, playerTables: playerTables, playerOrder: players)
    }
    
    static func componentToPlayerType(type: Component) -> PlayerTableType? {
        switch type {
        case is FryableComponent:
            return .frying
        case is ChoppableComponent:
            return .chopping
        case is CookableComponent:
            return .cooking
        default:
            return nil
        }
    }
    
}
