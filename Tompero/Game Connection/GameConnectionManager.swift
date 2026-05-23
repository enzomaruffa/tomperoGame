//
//  GameConnectionManager.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class GameConnectionManager {

    // MARK: - Static Variables
    static let shared = GameConnectionManager()

    // MARK: - Variables
    private let observers = NSHashTable<AnyObject>.weakObjects()
    private var observersSnapshot: [GameConnectionManagerObserver] {
        observers.allObjects.compactMap { $0 as? GameConnectionManagerObserver }
    }

    // MARK: - Methods
    private init() {
        LANConnectionManager.shared.subscribeDataObserver(observer: self)
    }

    func subscribe(observer: GameConnectionManagerObserver) {
        observers.add(observer as AnyObject)
    }

    func remove(observer: GameConnectionManagerObserver) {
        observers.remove(observer as AnyObject)
    }

    func removeAllObservers() {
        observers.removeAllObjects()
    }
    
    func sendEveryone(message: String) {
        do {
            print("[GameConnectionManager] Preparing message")
            let messageData = try JSONEncoder().encode(message)
            let wrapped = WirePayload(object: messageData, type: .string)
            LANConnectionManager.shared.sendEveryone(dataWrapper: wrapped)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func sendEveryone(orderList: [Order]) {
        do {
            print("[GameConnectionManager] Preparing order list")
            let ordersData = try JSONEncoder().encode(orderList)
            let wrapped = WirePayload(object: ordersData, type: .orders)
            LANConnectionManager.shared.sendEveryone(dataWrapper: wrapped)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func sendEveryone(deliveryNotification: OrderDeliveryNotification) {
        do {
            print("[GameConnectionManager] Preparing delivery notification")
            let notificationData = try JSONEncoder().encode(deliveryNotification)
            let wrapped = WirePayload(object: notificationData, type: .deliveryNotification)
            LANConnectionManager.shared.sendEveryone(dataWrapper: wrapped)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func sendEveryone(statistics: MatchStatistics) {
        do {
            print("[GameConnectionManager] Preparing statistics list")
            let statisticsData = try JSONEncoder().encode(statistics)
            let wrapped = WirePayload(object: statisticsData, type: .statistics)
            LANConnectionManager.shared.sendEveryone(dataWrapper: wrapped)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func send(ingredient: Ingredient, to player: String) {
        do {
            let ingredientData = try JSONEncoder().encode(ingredient)
            let wrapped = WirePayload(object: ingredientData, type: .ingredient)
            LANConnectionManager.shared.send(dataWrapper: wrapped, toDisplayName: player)
        } catch {
            print("[GameConnectionManager] Error encoding ingredient: \(error.localizedDescription)")
        }
    }

    func send(plate: Plate, to player: String) {
        do {
            let plateData = try JSONEncoder().encode(plate)
            let wrapped = WirePayload(object: plateData, type: .plate)
            LANConnectionManager.shared.send(dataWrapper: wrapped, toDisplayName: player)
        } catch {
            print("[GameConnectionManager] Error encoding plate: \(error.localizedDescription)")
        }
    }
    
}

// MARK: - LANDataObserver Methods
extension GameConnectionManager: LANDataObserver {
    
    func receiveData(wrapper: WirePayload) {
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
                
                observersSnapshot.forEach({ $0.receivePlate(plate: newPlate) })
            } catch let error {
                print("[GameConnectionManager] Error decoding: \(error.localizedDescription)")
            }
            
        case .ingredient:
            do {
                let ingredient = try JSONDecoder().decode(Ingredient.self, from: wrapper.object)
                
                let newIngredient = ingredient.findDowncast()
                
                observersSnapshot.forEach({ $0.receiveIngredient(ingredient: newIngredient) })
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
                observersSnapshot.forEach({ $0.receiveOrders(orders: newOrders) })
                
                // Chamar delegates que tem o receiveMessage
            } catch let error {
                print("[GameConnectionManager] Error decoding: \(error.localizedDescription)")
            }
            
        case .deliveryNotification:
            do {
                let deliveryNotification = try JSONDecoder().decode(OrderDeliveryNotification.self, from: wrapper.object)
                print("[GameConnectionManager] Received notification: \(deliveryNotification)")
                observersSnapshot.forEach({ $0.receiveDeliveryNotification(notification: deliveryNotification) })
                
                // Chamar delegates que tem o receiveMessage
            } catch let error {
                print("[GameConnectionManager] Error decoding: \(error.localizedDescription)")
            }
            
        case .statistics:
            do {
                let statistics = try JSONDecoder().decode(MatchStatistics.self, from: wrapper.object)
                print("[GameConnectionManager] Received statistics: \(statistics)")
                
                observersSnapshot.forEach({ $0.receiveStatistics(statistics: statistics) })
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
    }
    
}
