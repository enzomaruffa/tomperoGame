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
    
    static func generateRule(difficulty: GameDifficulty, players: [MCPeerID]) -> GameRule {
        
        // Variáveis de controle
        let totalPlayers = players.count
        let spacePerPlayer = 3
        
        var occupiedSpaces = 0
        let maxSpaces = totalPlayers * spacePerPlayer
        
        // Instancia as mesas dos jogadores
        var playerTables: [MCPeerID: [PlayerTable]] = [:]
        for player in players {
            playerTables[player] = Array(repeating: PlayerTable(), count: spacePerPlayer)
        }
        
        // Lista de ingredientes atuais
        var currentIngredients: [Ingredient.Type] = []
        
        // Gera o primeiro ingrediente aleatório
        var breadList = [SpaceshipHull(currentOwner: ""), DevilMashedBread(currentOwner: ""), Asteroid(currentOwner: "")]
        let firstIngredient = breadList.randomElement()!
        breadList.removeAll(where: {$0 == firstIngredient})
       
        // Incrementa variaveis
        occupiedSpaces += 1
        
        // Adiciona na lista de ingredientes
        currentIngredients.append(type(of: firstIngredient))
        
        // Adiciona o ingrediente na mesa de um jogador aleatório
        var randomPlayer = playerTables.keys.randomElement()!
        var randomTable = playerTables[randomPlayer]?.randomElement()!
        randomTable?.type = .ingredient
        randomTable?.ingredient = type(of: firstIngredient)

        currentIngredients.append(type(of: firstIngredient))
        
        //Adiciona um prato
        occupiedSpaces += 1
        
        // Pega só as mesas vazias. Filtra pelos jogadores e depois pelas mesas que possuem espaço vazio
        let players = playerTables.keys
        let playerWithEmptyTablesList = players.filter({ (playerTables[$0]?.contains(where: {$0.type == .empty}))! })
        randomPlayer = playerWithEmptyTablesList.randomElement()!
        randomTable = playerTables[randomPlayer]?.filter({ $0.type == .empty }).randomElement()!
        randomTable?.type = .plate
        
        // Ingredientes possíveis ainda:
        var possibleIngredients: [Ingredient] = [Broccoli(currentOwner: ""), Eyes(currentOwner: ""),
                                                 Horn(currentOwner: ""), MarsSand(currentOwner: ""),
                                                 MoonCheese(currentOwner: ""), SaturnOnionRings(currentOwner: ""),
                                                 Tardigrades(currentOwner: ""), Tentacle(currentOwner: "")]
        
        var actionsList: [Component.Type] = []
        
        while occupiedSpaces < maxSpaces {
            // Escolhe um novo ingrediente
            let newIngredient = possibleIngredients.randomElement()!
            possibleIngredients.removeAll(where: {$0 == newIngredient})
            
            // Se tem poucos, adiciona mais pães
            if possibleIngredients.count < 5 {
                possibleIngredients += breadList
            }
            
            // Verifica quantos espaços precisa pra ele:
            var supposedSpaces = 1
            
            for component in newIngredient.components {
                let componentType = type(of: component)
                if !actionsList.contains(where: { $0 == componentType}) {
                    supposedSpaces += 1
                }
            }
            
            // Não ultrapassa o limite de espaços
            guard occupiedSpaces + supposedSpaces >= maxSpaces else {
                continue
            }
            
            // Adiciona o ingrediente na lista
            occupiedSpaces += 1
            let players = playerTables.keys
            let playerWithEmptyTablesList = players.filter({ (playerTables[$0]?.contains(where: {$0.type == .empty}))! })
            randomPlayer = playerWithEmptyTablesList.randomElement()!
            randomTable = playerTables[randomPlayer]?.filter({ $0.type == .empty }).randomElement()!
            randomTable?.type = .ingredient
            randomTable?.ingredient = type(of: newIngredient)

            currentIngredients.append(type(of: newIngredient))
            
            // Se a ação dele ainda não existe, adiciona as ações na lista. Também adiciona bancada
            for component in newIngredient.components {
                
                let componentType = type(of: component)
                
                if !actionsList.contains(where: { $0 == componentType}) {
                    actionsList.append(componentType)

                    // Adiciona na mesa de um jogador aleatório
                    occupiedSpaces += 1
                    let players = playerTables.keys
                    let playerWithEmptyTablesList = players.filter({ (playerTables[$0]?.contains(where: {$0.type == .empty}))! })
                    randomPlayer = playerWithEmptyTablesList.randomElement()!
                    randomTable = playerTables[randomPlayer]?.filter({ $0.type == .empty }).randomElement()!
                    randomTable?.type = componentToPlayerType(type: component)!

                    // Se o ação já existe, pode ou não adicionar mais uma mesa que faz aquilo.
                } else if Int.random(in: 0...100) < 50 && occupiedSpaces < maxSpaces { // 50% de chance de adicionar novamente
                    
                    // Adiciona a ação novamente
                    occupiedSpaces += 1
                    let players = playerTables.keys
                    let playerWithEmptyTablesList = players.filter({ (playerTables[$0]?.contains(where: {$0.type == .empty}))! })
                    randomPlayer = playerWithEmptyTablesList.randomElement()!
                    randomTable = playerTables[randomPlayer]?.filter({ $0.type == .empty }).randomElement()!
                    randomTable?.type = componentToPlayerType(type: component)!
                }
            }
            
        }
        
        return GameRule(difficulty: difficulty, possibleIngredients: currentIngredients, playerTables: playerTables)
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
