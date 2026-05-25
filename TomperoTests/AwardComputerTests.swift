//
//  AwardComputerTests.swift
//  TomperoTests
//
//  Covers AwardComputer's allocation rules: clear winners take the
//  matching category, ties resolve alphabetically, players who lead
//  nothing fall back to "Sous Chef", zero-effort categories don't get
//  awarded by default.
//

import XCTest
@testable import SpaceSpice

final class AwardComputerTests: XCTestCase {

    func testDeliveryLeaderGetsTheDeliveryGuy() {
        let awards = AwardComputer.compute(awards: [
            "Alice": PlayerAwardStats(ordersDelivered: 7, chopActions: 2),
            "Bob": PlayerAwardStats(ordersDelivered: 3, chopActions: 5)
        ])
        XCTAssertEqual(awards["Alice"]?.title, "The Delivery Guy")
        XCTAssertEqual(awards["Alice"]?.supportingValue, 7)
        XCTAssertEqual(awards["Bob"]?.title, "Chop Chop")
        XCTAssertEqual(awards["Bob"]?.supportingValue, 5)
    }

    func testEveryPlayerGetsAnAwardOrFallback() {
        // Bob leads nothing — gets Sous Chef.
        let awards = AwardComputer.compute(awards: [
            "Alice": PlayerAwardStats(ordersDelivered: 5, chopActions: 4, cookActions: 3),
            "Bob": PlayerAwardStats(ordersDelivered: 0, chopActions: 0, cookActions: 0)
        ])
        XCTAssertEqual(awards["Alice"]?.title, "The Delivery Guy")
        XCTAssertEqual(awards["Bob"]?.title, "Sous Chef")
    }

    func testTieResolvesAlphabetically() {
        let awards = AwardComputer.compute(awards: [
            "Charlie": PlayerAwardStats(ordersDelivered: 5),
            "Alice": PlayerAwardStats(ordersDelivered: 5)
        ])
        // Alice and Charlie both have 5 deliveries — Alice (alphabetical first)
        // takes "The Delivery Guy"; Charlie falls through to the next category
        // they lead in (none, with these stats) → Sous Chef.
        XCTAssertEqual(awards["Alice"]?.title, "The Delivery Guy")
        XCTAssertEqual(awards["Charlie"]?.title, "Sous Chef")
    }

    func testZeroCountCategoriesAreNotAwarded() {
        // Nobody chopped — Chop Chop should NOT go to anyone.
        let awards = AwardComputer.compute(awards: [
            "Alice": PlayerAwardStats(ordersDelivered: 3, chopActions: 0),
            "Bob": PlayerAwardStats(ordersDelivered: 1, chopActions: 0)
        ])
        let titles = Set(awards.values.map { $0.title })
        XCTAssertFalse(titles.contains("Chop Chop"))
        XCTAssertTrue(titles.contains("The Delivery Guy"))
        XCTAssertTrue(titles.contains("Sous Chef"))
    }

    func testFourPlayersEachGetADifferentTitle() {
        let awards = AwardComputer.compute(awards: [
            "Alice": PlayerAwardStats(ordersDelivered: 9, chopActions: 1, cookActions: 1, fryActions: 1, platesCreated: 1, pipeForwards: 1),
            "Bob": PlayerAwardStats(ordersDelivered: 1, chopActions: 10, cookActions: 1, fryActions: 1, platesCreated: 1, pipeForwards: 1),
            "Carol": PlayerAwardStats(ordersDelivered: 1, chopActions: 1, cookActions: 12, fryActions: 1, platesCreated: 1, pipeForwards: 1),
            "Dan": PlayerAwardStats(ordersDelivered: 1, chopActions: 1, cookActions: 1, fryActions: 15, platesCreated: 1, pipeForwards: 1)
        ])
        XCTAssertEqual(awards["Alice"]?.title, "The Delivery Guy")
        XCTAssertEqual(awards["Bob"]?.title, "Chop Chop")
        XCTAssertEqual(awards["Carol"]?.title, "Hot Stuff")
        XCTAssertEqual(awards["Dan"]?.title, "Fry Master")
    }

    func testEmptyAwardsDictReturnsEmpty() {
        XCTAssertTrue(AwardComputer.compute(awards: [:]).isEmpty)
    }
}
