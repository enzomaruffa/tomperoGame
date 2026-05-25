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
        LANConnectionManager.shared.send(.string(message))
    }

    func sendEveryone(orderList: [Order]) {
        LANConnectionManager.shared.send(.orders(orderList))
    }

    func sendEveryone(deliveryNotification: OrderDeliveryNotification) {
        LANConnectionManager.shared.send(.deliveryNotification(deliveryNotification))
    }

    func sendEveryone(statistics: MatchStatistics) {
        LANConnectionManager.shared.send(.statistics(statistics))
    }

    func send(ingredient: Ingredient, to player: String) {
        LANConnectionManager.shared.send(.ingredient(ingredient), to: player)
    }

    func send(plate: Plate, to player: String) {
        LANConnectionManager.shared.send(.plate(plate), to: player)
    }
}

// MARK: - LANDataObserver Methods
extension GameConnectionManager: LANDataObserver {

    func receiveData(payload: WirePayload) {
        switch payload {
        case .plate(let plate):
            // Restore concrete Ingredient subclasses + set their currentState
            // before the scene picks the plate up.
            let newIngredients = plate.ingredients.map { $0.findDowncast() }
            newIngredients.forEach { $0.currentState = $0.finalState }
            let newPlate = Plate()
            newPlate.ingredients = newIngredients
            observersSnapshot.forEach { $0.receivePlate(plate: newPlate) }

        case .ingredient(let ingredient):
            let newIngredient = ingredient.findDowncast()
            observersSnapshot.forEach { $0.receiveIngredient(ingredient: newIngredient) }

        case .orders(let orders):
            let newOrders: [Order] = orders.map { order in
                let newOrder = Order(timeLeft: order.timeLeft)
                newOrder.totalTime = order.totalTime
                newOrder.number = order.number
                newOrder.ingredients = order.ingredients.map { $0.findDowncast() }
                return newOrder
            }
            observersSnapshot.forEach { $0.receiveOrders(orders: newOrders) }

        case .deliveryNotification(let notification):
            observersSnapshot.forEach { $0.receiveDeliveryNotification(notification: notification) }

        case .statistics(let statistics):
            observersSnapshot.forEach { $0.receiveStatistics(statistics: statistics) }

        case .string(let message):
            Log.network.debug("Received string message: \(message, privacy: .public)")

        case .playerData, .gameRule:
            // Routed through LANMatchmakingObserver; should not reach here.
            break
        }
    }
}
