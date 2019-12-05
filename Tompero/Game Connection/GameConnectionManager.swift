//
//  GameConnectionManager.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class GameConnectionManager {
    
    // MARK: - Static Variables
    static let shared = GameConnectionManager()
     
    // MARK: - Variables
    var observers: [GameConnectionManagerObserver] = []
    
    // MARK: - Methods
    private init() {
        MCManager.shared.subscribeDataObserver(observer: self)
    }
    
    func subscribe(observer: GameConnectionManagerObserver) {
        observers.append(observer)
    }
    
    func sendAll(message: String) {
        do {
            print("[GameConnectionManager] Preparing message")
            let messageData = try JSONEncoder().encode(message)
            let wrapped = MCDataWrapper(object: messageData, type: .string)
            MCManager.shared.sendEveryone(dataWrapper: wrapped)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func send(ingredient: Ingredient, to player: String) {
        do {
            print("[GameConnectionManager] Preparing ingredient")
            let ingredientData = try JSONEncoder().encode(ingredient)
            let wrapped = MCDataWrapper(object: ingredientData, type: .ingredient)
            print(MCManager.shared.connectedPeers)
            MCManager.shared.connectedPeers?.forEach({ print($0.displayName) })
            let peer = MCManager.shared.connectedPeers?.filter({ $0.displayName == player })
            MCManager.shared.send(dataWrapper: wrapped, to: peer!)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func send(plate: Plate, to player: String) {
        do {
            print("[GameConnectionManager] Preparing plate")
            let plateData = try JSONEncoder().encode(plate)
            let wrapped = MCDataWrapper(object: plateData, type: .plate)
            let peer = MCManager.shared.connectedPeers?.filter({ $0.displayName == player })
            MCManager.shared.send(dataWrapper: wrapped, to: peer!)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
}

// MARK: - MCManagerDataObserver Methoods
extension GameConnectionManager: MCManagerDataObserver {
    
    func receiveData(wrapper: MCDataWrapper) {
        print("[GameConnectionManager] Received data with type: \(wrapper.type)")
        
        switch wrapper.type {
        case .plate:
            do {
                let plate = try JSONDecoder().decode(Plate.self, from: wrapper.object)
                observers.forEach({ $0.receivePlate(plate: plate) })
            } catch let error {
                print("[GameConnectionManager] Error decoding: \(error.localizedDescription)")
            }
            
        case .ingredient:
            do {
                let ingredient = try JSONDecoder().decode(Ingredient.self, from: wrapper.object)
                observers.forEach({ $0.receiveIngredient(ingredient: ingredient) })
            } catch let error {
                print("[GameConnectionManager] Error decoding: \(error.localizedDescription)")
            }
            
        case .string:
            do {
                let message = try JSONDecoder().decode(String.self, from: wrapper.object)
                print("[GameConnectionManager] Received message: \(message)")
                
                // Chamar delegates que tem o receiveMessage
            } catch let error {
                print("[GameConnectionManager] Error decoding: \(error.localizedDescription)")
            }
        default:
            print("[GameConnectionManager] Unknown type received")
        }
        // TODO: Decodificar o ingrediente em outrostipos
    }

}
