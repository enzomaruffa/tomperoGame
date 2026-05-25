//
//  MatchClockTests.swift
//  TomperoTests
//
//  Covers the 60-frame countdown semantics of MatchClock, including the
//  intentionally off-by-one `< 15` warning and `< 0` times-up thresholds
//  inherited from the original GameScene logic.
//

import XCTest
@testable import SpaceSpice

final class MatchClockTests: XCTestCase {

    func testNoOpBeforeStart() {
        let clock = MatchClock(initialSeconds: 30)
        var warning = 0
        clock.onWarning = { warning += 1 }

        for _ in 0..<300 {
            clock.tick()
        }

        XCTAssertEqual(clock.timeRemaining, 30)
        XCTAssertEqual(warning, 0)
    }

    func testSixtyTicksDropsOneSecond() {
        let clock = MatchClock(initialSeconds: 30)
        clock.start()

        for _ in 0..<60 {
            clock.tick()
        }
        XCTAssertEqual(clock.timeRemaining, 29)

        for _ in 0..<60 {
            clock.tick()
        }
        XCTAssertEqual(clock.timeRemaining, 28)
    }

    func testOnSecondElapsedFiresOncePerSecond() {
        let clock = MatchClock(initialSeconds: 30)
        var seconds = 0
        clock.onSecondElapsed = { seconds += 1 }
        clock.start()

        for _ in 0..<(60 * 3) {
            clock.tick()
        }

        XCTAssertEqual(seconds, 3)
    }

    func testWarningFiresExactlyOnceOnSubFifteen() {
        // 17s left, tick down to 15 (no warning), then 14 (warning fires).
        let clock = MatchClock(initialSeconds: 17)
        var warning = 0
        clock.onWarning = { warning += 1 }
        clock.start()

        for _ in 0..<60 { clock.tick() } // 17 -> 16
        XCTAssertEqual(warning, 0)
        for _ in 0..<60 { clock.tick() } // 16 -> 15
        XCTAssertEqual(warning, 0)
        for _ in 0..<60 { clock.tick() } // 15 -> 14
        XCTAssertEqual(warning, 1)
        for _ in 0..<(60 * 5) { clock.tick() } // keep ticking
        XCTAssertEqual(warning, 1, "Warning must not fire again after first sub-15 tick")
    }

    func testTimesUpFiresExactlyOnceWhenTimerGoesNegative() {
        let clock = MatchClock(initialSeconds: 2)
        var timesUp = 0
        clock.onTimesUp = { timesUp += 1 }
        clock.start()

        for _ in 0..<60 { clock.tick() } // 2 -> 1
        XCTAssertEqual(timesUp, 0)
        for _ in 0..<60 { clock.tick() } // 1 -> 0
        XCTAssertEqual(timesUp, 0)
        for _ in 0..<60 { clock.tick() } // 0 -> -1
        XCTAssertEqual(timesUp, 1)
        for _ in 0..<(60 * 3) { clock.tick() }
        XCTAssertEqual(timesUp, 1, "Times-up must fire exactly once")
    }

    func testStartIsIdempotent() {
        let clock = MatchClock(initialSeconds: 5)
        clock.start()
        clock.start()
        for _ in 0..<60 { clock.tick() }
        XCTAssertEqual(clock.timeRemaining, 4)
    }
}
