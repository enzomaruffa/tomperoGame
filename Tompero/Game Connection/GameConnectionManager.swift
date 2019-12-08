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
    
    func sendEveryone(message: String) {
        do {
            print("[GameConnectionManager] Preparing message")
            let messageData = try JSONEncoder().encode(message)
            let wrapped = MCDataWrapper(object: messageData, type: .string)
            MCManager.shared.sendEveryone(dataWrapper: wrapped)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func sendEveryone(orderList: [Order]) {
        do {
            print("[GameConnectionManager] Preparing order list")
            let ordersData = try JSONEncoder().encode(orderList)
            let wrapped = MCDataWrapper(object: ordersData, type: .orders)
            MCManager.shared.sendEveryone(dataWrapper: wrapped)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func sendEveryone(deliveryNotification: OrderDeliveryNotification) {
        do {
            print("[GameConnectionManager] Preparing delivery notification")
            let notificationData = try JSONEncoder().encode(deliveryNotification)
            let wrapped = MCDataWrapper(object: notificationData, type: .deliveryNotification)
            MCManager.shared.sendEveryone(dataWrapper: wrapped)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func send(ingredient: Ingredient, to player: String) {
        do {
            print("[GameConnectionManager] Preparing ingredient")
            let ingredientData = try JSONEncoder().encode(ingredient)
            let jsonString = String(data: ingredientData, encoding: .utf8)
            print(jsonString)
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
                
                // downcasting plate
                let newIngredients = plate.ingredients.map({ $0.findDowncast() })
                newIngredients.forEach({ $0.currentState = $0.finalState })
                let newPlate = Plate()
                newPlate.ingredients = newIngredients
                
                newIngredients.forEach({ print($0.texturePrefix, type(of: $0)) })
                
                observers.forEach({ $0.receivePlate(plate: newPlate) })
            } catch let error {
                print("[GameConnectionManager] Error decoding: \(error.localizedDescription)")
            }
            
        case .ingredient:
            do {
                let ingredient = try JSONDecoder().decode(Ingredient.self, from: wrapper.object)
                
                let newIngredient = ingredient.findDowncast()
                
                observers.forEach({ $0.receiveIngredient(ingredient: newIngredient) })
            } catch let error {
                print("[GameConnectionManager] Error decoding: \(error.localizedDescription)")
            }
            
        case .orders:
            do {
                let orders = try JSONDecoder().decode([Order].self, from: wrapper.object)
                
                var newOrders: [Order] = []
                for order in orders {
                    let newOrder = Order(timeLeft: order.timeLeft)
                    newOrder.totalTime = order.totalTime
                    newOrder.number = order.number
                    newOrder.ingredients = order.ingredients.map({ $0.findDowncast() })
                    newOrders.append(newOrder)
                }
                
                print("[GameConnectionManager] Received orderList: \(newOrders)")
                observers.forEach({ $0.receiveOrders(orders: newOrders) })
                
                // Chamar delegates que tem o receiveMessage
            } catch let error {
                print("[GameConnectionManager] Error decoding: \(error.localizedDescription)")
            }
            
        case .deliveryNotification:
            do {
                let deliveryNotification = try JSONDecoder().decode(OrderDeliveryNotification.self, from: wrapper.object)
                print("[GameConnectionManager] Received notification: \(deliveryNotification)")
                observers.forEach({ $0.receiveDeliveryNotification(notification: deliveryNotification) })
                
                // Chamar delegates que tem o receiveMessage
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
