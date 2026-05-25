//
//  PlayerStatsStoreTests.swift
//  TomperoTests
//
//  Covers PlayerStatsStore's record() semantics: aggregate accumulation,
//  per-difficulty best-score tracking that only beats forward, lifetime
//  action counters that add properly.
//

import XCTest
@testable import SpaceSpice

final class PlayerStatsStoreTests: XCTestCase {

    private var defaults: UserDefaults!
    private var store: PlayerStatsStore!

    override func setUp() {
        super.setUp()
        let suite = "PlayerStatsStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
        // Wipe so every test starts at zero
        for key in defaults.dictionaryRepresentation().keys { defaults.removeObject(forKey: key) }
        store = PlayerStatsStore(defaults: defaults)
    }

    override func tearDown() {
        store.reset()
        defaults = nil
        store = nil
        super.tearDown()
    }

    private func stats(difficulty: GameDifficulty, delivered: Int, generated: Int, points: Int) -> MatchStatistics {
        let rule = GameRule(difficulty: difficulty, possibleIngredients: [], playerTables: [:], playerOrder: [])
        let s = MatchStatistics(ruleUsed: rule)
        s.totalDeliveredOrders = delivered
        s.totalGeneratedOrders = generated
        s.totalPoints = points
        return s
    }

    func testRecordingFirstMatchSetsAggregates() throws {
        store.record(
            matchStatistics: stats(difficulty: .easy, delivered: 7, generated: 10, points: 84),
            localActions: PlayerAwardStats(ordersDelivered: 7, chopActions: 5, cookActions: 2, fryActions: 0, platesCreated: 7, pipeForwards: 1)
        )
        XCTAssertEqual(store.totalMatches, 1)
        XCTAssertEqual(store.totalOrdersDelivered, 7)
        XCTAssertEqual(store.totalOrdersGenerated, 10)
        XCTAssertEqual(store.totalCoinsEarned, 84)
        XCTAssertEqual(store.bestScore(for: .easy), 84)
        XCTAssertEqual(store.lifetimeActions.chopActions, 5)
        XCTAssertEqual(store.lifetimeActions.platesCreated, 7)
        XCTAssertEqual(try XCTUnwrap(store.accuracy), 0.7, accuracy: 0.001)
    }

    func testMultipleMatchesAccumulate() {
        let easyStats = stats(difficulty: .easy, delivered: 5, generated: 8, points: 40)
        let mediumStats = stats(difficulty: .medium, delivered: 6, generated: 9, points: 72)

        store.record(matchStatistics: easyStats, localActions: PlayerAwardStats(ordersDelivered: 5, chopActions: 3, cookActions: 0, fryActions: 0, platesCreated: 5, pipeForwards: 0))
        store.record(matchStatistics: mediumStats, localActions: PlayerAwardStats(ordersDelivered: 6, chopActions: 2, cookActions: 4, fryActions: 0, platesCreated: 6, pipeForwards: 1))

        XCTAssertEqual(store.totalMatches, 2)
        XCTAssertEqual(store.totalOrdersDelivered, 11)
        XCTAssertEqual(store.totalOrdersGenerated, 17)
        XCTAssertEqual(store.totalCoinsEarned, 112)
        XCTAssertEqual(store.bestScore(for: .easy), 40)
        XCTAssertEqual(store.bestScore(for: .medium), 72)
        XCTAssertEqual(store.bestScore(for: .hard), 0)
        XCTAssertEqual(store.lifetimeActions.chopActions, 5)
        XCTAssertEqual(store.lifetimeActions.cookActions, 4)
    }

    func testBestScoreOnlyUpdatesWhenBeaten() {
        store.record(matchStatistics: stats(difficulty: .hard, delivered: 3, generated: 5, points: 150), localActions: .zero)
        XCTAssertEqual(store.bestScore(for: .hard), 150)

        // Lower score — should not overwrite
        store.record(matchStatistics: stats(difficulty: .hard, delivered: 2, generated: 5, points: 90), localActions: .zero)
        XCTAssertEqual(store.bestScore(for: .hard), 150)

        // Beat it
        store.record(matchStatistics: stats(difficulty: .hard, delivered: 4, generated: 5, points: 200), localActions: .zero)
        XCTAssertEqual(store.bestScore(for: .hard), 200)
    }

    func testAccuracyNilOnFreshStore() {
        XCTAssertNil(store.accuracy)
    }

    func testResetClearsEverything() {
        store.record(matchStatistics: stats(difficulty: .easy, delivered: 5, generated: 5, points: 60), localActions: PlayerAwardStats(ordersDelivered: 5, chopActions: 1, cookActions: 1, fryActions: 1, platesCreated: 5, pipeForwards: 1))
        store.reset()
        XCTAssertEqual(store.totalMatches, 0)
        XCTAssertEqual(store.totalOrdersDelivered, 0)
        XCTAssertEqual(store.bestScore(for: .easy), 0)
        XCTAssertEqual(store.lifetimeActions, .zero)
    }
}
