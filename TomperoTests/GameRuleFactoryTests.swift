//
//  GameRuleFactoryTests.swift
//  TomperoTests
//
//  Invariants for the procedural rule generator. The factory is heavily
//  randomized internally, so these focus on properties that must hold for
//  every roll, plus regressions for crashes we've actually hit (single
//  real player with empty slots, etc.).
//

import XCTest
@testable import SpaceSpice

final class GameRuleFactoryTests: XCTestCase {

    private let emptyName = "__empty__"

    // MARK: - Shape invariants

    func testFourRealPlayersProducesTwelveTables() {
        let rule = GameRuleFactory.generateRule(
            difficulty: .medium,
            players: ["A", "B", "C", "D"]
        )

        let total = rule.playerTables.values.reduce(0) { $0 + $1.count }
        XCTAssertEqual(total, 12)
        XCTAssertEqual(rule.playerTables.count, 4)
        for tables in rule.playerTables.values {
            XCTAssertEqual(tables.count, 3)
        }
    }

    func testThreeRealPlayersProducesNineTables() {
        let rule = GameRuleFactory.generateRule(
            difficulty: .hard,
            players: ["A", "B", "C", emptyName]
        )

        let total = rule.playerTables.values.reduce(0) { $0 + $1.count }
        XCTAssertEqual(total, 9)
        XCTAssertEqual(rule.playerTables.count, 3)
        XCTAssertNil(rule.playerTables[emptyName])
    }

    func testTwoRealPlayersProducesSixTables() {
        let rule = GameRuleFactory.generateRule(
            difficulty: .easy,
            players: ["A", "B", emptyName, emptyName]
        )

        let total = rule.playerTables.values.reduce(0) { $0 + $1.count }
        XCTAssertEqual(total, 6)
        XCTAssertEqual(rule.playerTables.count, 2)
    }

    func testPlayerOrderMatchesInputIncludingEmpties() {
        let players = ["Alice", emptyName, "Bob", emptyName]
        let rule = GameRuleFactory.generateRule(difficulty: .easy, players: players)
        XCTAssertEqual(rule.playerOrder, players)
    }

    func testDifficultyIsPropagated() {
        XCTAssertEqual(
            GameRuleFactory.generateRule(difficulty: .easy, players: ["A", "B"]).difficulty,
            .easy
        )
        XCTAssertEqual(
            GameRuleFactory.generateRule(difficulty: .medium, players: ["A", "B"]).difficulty,
            .medium
        )
        XCTAssertEqual(
            GameRuleFactory.generateRule(difficulty: .hard, players: ["A", "B"]).difficulty,
            .hard
        )
    }

    // MARK: - Content invariants

    func testNoTableLeftEmptyAfterGeneration() {
        // Run a few times because the factory is randomized; assert the
        // post-condition that the "fill empties" pass leaves no .empty tables.
        for _ in 0..<10 {
            let rule = GameRuleFactory.generateRule(
                difficulty: .medium,
                players: ["A", "B", "C", "D"]
            )

            for (player, tables) in rule.playerTables {
                for table in tables {
                    XCTAssertNotEqual(
                        table.type,
                        .empty,
                        "Found empty table for player \(player) — fill pass missed it"
                    )
                }
            }
        }
    }

    func testEveryIngredientTableHasIngredient() {
        for _ in 0..<10 {
            let rule = GameRuleFactory.generateRule(
                difficulty: .medium,
                players: ["A", "B"]
            )

            for tables in rule.playerTables.values {
                for table in tables where table.type == .ingredient {
                    XCTAssertNotNil(
                        table.ingredient,
                        "Ingredient-type table missing its ingredient"
                    )
                }
            }
        }
    }

    // MARK: - Regressions

    func testSingleRealPlayerDoesNotCrash() {
        // playersWithSomethingList.randomElement()! used to crash the fill
        // pass on this input. Just running without trapping is the assertion.
        let rule = GameRuleFactory.generateRule(
            difficulty: .easy,
            players: ["Solo", emptyName, emptyName, emptyName]
        )
        XCTAssertEqual(rule.playerTables.count, 1)
        XCTAssertEqual(rule.playerTables["Solo"]?.count, 3)
    }

    // MARK: - componentToPlayerType mapping

    func testComponentMappingChoppable() {
        let component = ChoppableComponent(chopProgress: 0, chopIncrement: 1, chopCap: 1)
        XCTAssertEqual(GameRuleFactory.componentToPlayerType(type: component), .chopping)
    }

    func testComponentMappingCookable() {
        let component = CookableComponent(cookProgress: 0, cookIncrement: 1, cookCap: 1, burnCap: 2)
        XCTAssertEqual(GameRuleFactory.componentToPlayerType(type: component), .cooking)
    }

    func testComponentMappingFryable() {
        let component = FryableComponent(fryProgress: 0, fryIncrement: 1, fryCap: 1, burnCap: 2)
        XCTAssertEqual(GameRuleFactory.componentToPlayerType(type: component), .frying)
    }
}
