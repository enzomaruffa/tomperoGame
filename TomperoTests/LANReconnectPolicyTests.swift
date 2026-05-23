//
//  LANReconnectPolicyTests.swift
//  TomperoTests
//

import XCTest
@testable import SpaceSpice

final class LANReconnectPolicyTests: XCTestCase {

    func testReturnsScheduleThenSaturatesAtLastEntry() {
        var policy = LANReconnectPolicy(schedule: [1, 2, 4], giveUpAfter: .greatestFiniteMagnitude)
        XCTAssertEqual(policy.next(), 1)
        XCTAssertEqual(policy.next(), 2)
        XCTAssertEqual(policy.next(), 4)
        XCTAssertEqual(policy.next(), 4) // saturates at last
    }

    func testGivesUpAfterBudget() {
        // 0s budget — should give up on the very first call.
        var policy = LANReconnectPolicy(schedule: [1], giveUpAfter: -1)
        XCTAssertNil(policy.next())
    }

    func testResetClearsAttemptAndStartTime() {
        var policy = LANReconnectPolicy(schedule: [1, 2], giveUpAfter: .greatestFiniteMagnitude)
        _ = policy.next()
        _ = policy.next()
        policy.reset()
        XCTAssertEqual(policy.next(), 1)
    }
}
