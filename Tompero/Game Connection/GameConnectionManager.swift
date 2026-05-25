//
//  GameConnectionManager.swift
//  Tompero
//
//  Thin transformer over LANConnectionManager: subscribes to its raw
//  WirePayload stream, restores concrete Ingredient subclasses via
//  findDowncast(), and republishes typed GameEvents that the scene
//  layer sinks on. The hand-rolled NSHashTable observer pattern was
//  removed in favor of a single PassthroughSubject so subscribers can
//  filter/map with Combine.
//

import Combine
import Foundation

final class GameConnectionManager {

    static let shared = GameConnectionManager()

    /// Typed game events. GameScene `.sink`s on this and switches on the case.
    let events = PassthroughSubject<GameEvent, Never>()

    private var cancellables = Set<AnyCancellable>()

    private init() {
        LANConnectionManager.shared.payloadReceived
            .sink { [weak self] payload in
                self?.handle(payload: payload)
            }
            .store(in: &cancellables)
    }

    // MARK: - Sending

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

    // MARK: - Incoming

    private func handle(payload: WirePayload) {
        switch payload {
        case .plate(let plate):
            // Restore concrete Ingredient subclasses + set their currentState
            // before the scene picks the plate up.
            let newIngredients = plate.ingredients.map { $0.findDowncast() }
            newIngredients.forEach { $0.currentState = $0.finalState }
            let newPlate = Plate()
            newPlate.ingredients = newIngredients
            events.send(.plate(newPlate))

        case .ingredient(let ingredient):
            events.send(.ingredient(ingredient.findDowncast()))

        case .orders(let orders):
            let newOrders: [Order] = orders.map { order in
                let newOrder = Order(timeLeft: order.timeLeft)
                newOrder.totalTime = order.totalTime
                newOrder.number = order.number
                newOrder.ingredients = order.ingredients.map { $0.findDowncast() }
                return newOrder
            }
            events.send(.orders(newOrders))

        case .deliveryNotification(let notification):
            events.send(.deliveryNotification(notification))

        case .statistics(let statistics):
            events.send(.statistics(statistics))

        case .pauseRequest(let paused):
            events.send(.pauseRequest(paused))

        case .string(let message):
            Log.network.debug("Received string message: \(message, privacy: .public)")

        case .playerData, .gameRule:
            // Routed via LANConnectionManager.matchmakingEvents; should not
            // arrive on payloadReceived.
            break
        }
    }
}
