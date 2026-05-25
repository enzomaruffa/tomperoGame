//
//  DeliveryScorerTests.swift
//  TomperoTests
//
//  Covers the pure scoring math behind plate delivery — what counts as a
//  successful match, how the difficulty multiplier applies, and the
//  matched-order index that GameScene uses to dequeue.
//

import XCTest
@testable import SpaceSpice

final class DeliveryScorerTests: XCTestCase {

    private func order(timeLeft: Float, ingredients: [Ingredient]) -> Order {
        let o = Order(timeLeft: timeLeft)
        o.ingredients = ingredients
        return o
    }

    private func plate(_ ingredients: [Ingredient]) -> Plate {
        let p = Plate()
        p.ingredients = ingredients
        return p
    }

    // MARK: - Success path

    func testMatchingPlateScoresBaseTimesEasyBonus() {
        let target = order(timeLeft: 30, ingredients: [Asteroid(), MoonCheese()])
        let outcome = DeliveryScorer.score(
            plate: plate([Asteroid(), MoonCheese()]),
            against: [target],
            difficulty: .easy
        )

        XCTAssertTrue(outcome.success)
        XCTAssertEqual(outcome.coinsAdded, target.score * 1)
        XCTAssertEqual(outcome.matchedOrderIndex, 0)
    }

    func testMediumDoublesScore() {
        let target = order(timeLeft: 30, ingredients: [Asteroid(), MoonCheese()])
        let outcome = DeliveryScorer.score(
            plate: plate([MoonCheese(), Asteroid()]),
            against: [target],
            difficulty: .medium
        )

        XCTAssertTrue(outcome.success)
        XCTAssertEqual(outcome.coinsAdded, target.score * 2)
    }

    func testHardTriplesScore() {
        let target = order(timeLeft: 30, ingredients: [Asteroid(), MoonCheese(), Tentacle()])
        let outcome = DeliveryScorer.score(
            plate: plate([Tentacle(), Asteroid(), MoonCheese()]),
            against: [target],
            difficulty: .hard
        )

        XCTAssertTrue(outcome.success)
        XCTAssertEqual(outcome.coinsAdded, target.score * 3)
    }

    func testIngredientOrderDoesNotMatter() {
        let target = order(timeLeft: 5, ingredients: [Asteroid(), Tentacle(), Eyes()])
        let outcome = DeliveryScorer.score(
            plate: plate([Eyes(), Asteroid(), Tentacle()]),
            against: [target],
            difficulty: .easy
        )

        XCTAssertTrue(outcome.success)
    }

    // MARK: - Failure paths

    func testMissingIngredientFails() {
        let target = order(timeLeft: 30, ingredients: [Asteroid(), MoonCheese(), Tentacle()])
        let outcome = DeliveryScorer.score(
            plate: plate([Asteroid(), MoonCheese()]),
            against: [target],
            difficulty: .easy
        )

        XCTAssertFalse(outcome.success)
        XCTAssertEqual(outcome.coinsAdded, 0)
        XCTAssertNil(outcome.matchedOrderIndex)
    }

    func testExtraIngredientFails() {
        let target = order(timeLeft: 30, ingredients: [Asteroid(), MoonCheese()])
        let outcome = DeliveryScorer.score(
            plate: plate([Asteroid(), MoonCheese(), Eyes()]),
            against: [target],
            difficulty: .easy
        )

        XCTAssertFalse(outcome.success)
    }

    func testWrongIngredientFails() {
        let target = order(timeLeft: 30, ingredients: [Asteroid(), MoonCheese()])
        let outcome = DeliveryScorer.score(
            plate: plate([Asteroid(), Tentacle()]),
            against: [target],
            difficulty: .easy
        )

        XCTAssertFalse(outcome.success)
    }

    func testEmptyOrdersAlwaysFails() {
        let outcome = DeliveryScorer.score(
            plate: plate([Asteroid()]),
            against: [],
            difficulty: .hard
        )

        XCTAssertFalse(outcome.success)
        XCTAssertNil(outcome.matchedOrderIndex)
    }

    // MARK: - Index reporting

    func testMatchedOrderIndexIsTheFirstMatch() {
        let first = order(timeLeft: 30, ingredients: [Asteroid()])
        let second = order(timeLeft: 30, ingredients: [Asteroid()])

        let outcome = DeliveryScorer.score(
            plate: plate([Asteroid()]),
            against: [first, second],
            difficulty: .easy
        )

        XCTAssertEqual(outcome.matchedOrderIndex, 0)
    }

    func testMatchedOrderIndexSkipsNonMatches() {
        let nonMatching = order(timeLeft: 30, ingredients: [Tentacle()])
        let matching = order(timeLeft: 30, ingredients: [Asteroid()])

        let outcome = DeliveryScorer.score(
            plate: plate([Asteroid()]),
            against: [nonMatching, matching],
            difficulty: .easy
        )

        XCTAssertEqual(outcome.matchedOrderIndex, 1)
    }
}
