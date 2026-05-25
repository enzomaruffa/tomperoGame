//
//  OrderGenerator.swift
//  Tompero
//
//  Host-only order spawn loop. Pulled out of GameScene's `updateOrders`
//  so the cadence logic can be tested without an SKScene + the scene's
//  update tick stays a thin orchestrator.
//
//  The scene calls `tick(state:rule:onSpawn:)` once per frame. The
//  generator increments the spawn counter, checks the spawn predicates,
//  and invokes `onSpawn` once per spawn so the caller can play SFX,
//  animate the order list, and broadcast the updated order list.
//

import Foundation

final class OrderGenerator {

    /// Frames between cadence-driven spawns. 60 fps × 10 = ten seconds.
    static let timeBetweenOrders = 10 * 60

    /// Cap on simultaneously-active orders.
    static let maxOrders = 3

    /// Spawn one new order if the predicates allow it. Returns true when an
    /// order was generated so the caller can play "order up" SFX.
    @discardableResult
    func tick(state: MatchState, rule: GameRule, onSpawn: (Order) -> Void) -> Bool {
        state.orderGenerationCounter += 1

        let cadenceMet = state.orderGenerationCounter >= OrderGenerator.timeBetweenOrders
            && state.orders.count < OrderGenerator.maxOrders
        let emptyDuringMatch = state.timerStarted && state.orders.isEmpty

        guard cadenceMet || emptyDuringMatch else { return false }

        let order = rule.generateOrder()
        state.appendOrder(order)
        onSpawn(order)
        state.orderGenerationCounter = 0

        // Timer kicks off on the first generated order.
        if !state.timerStarted {
            state.timerStarted = true
        }
        return true
    }
}
