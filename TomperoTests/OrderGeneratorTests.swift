//
//  OrderGeneratorTests.swift
//  TomperoTests
//
//  Covers the spawn cadence + cap rules pulled out of GameScene.updateOrders.
//

import XCTest
@testable import SpaceSpice

final class OrderGeneratorTests: XCTestCase {

    private func makeState(orderCount: Int = 0, timerStarted: Bool = false) -> MatchState {
        let s = MatchState()
        s.timerStarted = timerStarted
        s.orderGenerationCounter = 0
        // Fill with placeholder orders if requested
        for _ in 0..<orderCount {
            s.orders.append(Order(timeLeft: 30))
        }
        return s
    }

    private func makeRule() -> GameRule {
        GameRule(
            difficulty: .easy,
            possibleIngredients: [Asteroid()],
            playerTables: ["A": []],
            playerOrder: ["A"]
        )
    }

    func testDoesNotSpawnBeforeCadenceAndBeforeTimerStart() {
        let state = makeState()
        let generator = OrderGenerator()
        let rule = makeRule()

        // 5 minutes worth of ticks, counter rising — no empty + timer combo
        // since timerStarted is false; no spawn because counter < threshold
        // until the very last tick.
        var spawns = 0
        for _ in 0..<(OrderGenerator.timeBetweenOrders - 1) {
            if generator.tick(state: state, rule: rule, onSpawn: { _ in }) { spawns += 1 }
        }
        XCTAssertEqual(spawns, 0)
        XCTAssertEqual(state.orders.count, 0)
    }

    func testSpawnsAtCadenceThreshold() {
        let state = makeState()
        let generator = OrderGenerator()
        let rule = makeRule()

        var spawned: Order?
        for _ in 0..<OrderGenerator.timeBetweenOrders {
            _ = generator.tick(state: state, rule: rule) { order in spawned = order }
        }

        XCTAssertNotNil(spawned)
        XCTAssertEqual(state.orders.count, 1)
        XCTAssertTrue(state.timerStarted, "First spawn must kick off the match timer")
        XCTAssertEqual(state.orderGenerationCounter, 0, "Counter must reset on spawn")
    }

    func testCadenceSpawnsAgainAfterReset() {
        let state = makeState()
        let generator = OrderGenerator()
        let rule = makeRule()

        for _ in 0..<OrderGenerator.timeBetweenOrders {
            _ = generator.tick(state: state, rule: rule, onSpawn: { _ in })
        }
        XCTAssertEqual(state.orders.count, 1)

        for _ in 0..<(OrderGenerator.timeBetweenOrders - 1) {
            _ = generator.tick(state: state, rule: rule, onSpawn: { _ in })
        }
        XCTAssertEqual(state.orders.count, 1, "Should not spawn before cadence threshold")
        _ = generator.tick(state: state, rule: rule, onSpawn: { _ in })
        XCTAssertEqual(state.orders.count, 2)
    }

    func testRespectsMaxOrdersCap() {
        let state = makeState(orderCount: OrderGenerator.maxOrders, timerStarted: true)
        let generator = OrderGenerator()
        let rule = makeRule()

        var spawns = 0
        for _ in 0..<(OrderGenerator.timeBetweenOrders * 3) {
            if generator.tick(state: state, rule: rule, onSpawn: { _ in }) { spawns += 1 }
        }

        XCTAssertEqual(spawns, 0)
        XCTAssertEqual(state.orders.count, OrderGenerator.maxOrders)
    }

    func testImmediateSpawnWhenEmptyAfterTimerStarted() {
        // Match in progress, all orders cleared (delivered/expired). Even if
        // counter is well below threshold, an empty list must spawn next tick.
        let state = makeState(timerStarted: true)
        let generator = OrderGenerator()
        let rule = makeRule()

        let didSpawn = generator.tick(state: state, rule: rule, onSpawn: { _ in })

        XCTAssertTrue(didSpawn)
        XCTAssertEqual(state.orders.count, 1)
    }

    func testOnSpawnCallbackFiresOncePerSpawn() {
        let state = makeState(timerStarted: true)
        let generator = OrderGenerator()
        let rule = makeRule()

        var callCount = 0
        _ = generator.tick(state: state, rule: rule) { _ in callCount += 1 }
        XCTAssertEqual(callCount, 1)

        for _ in 0..<(OrderGenerator.timeBetweenOrders * 2) {
            _ = generator.tick(state: state, rule: rule) { _ in callCount += 1 }
        }
        // 1 immediate + 2 cadence = 3 total spawns
        XCTAssertEqual(callCount, 3)
    }
}
