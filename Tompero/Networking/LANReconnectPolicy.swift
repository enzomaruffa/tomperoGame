//
//  LANReconnectPolicy.swift
//  Tompero
//

import Foundation

/// Exponential-backoff schedule for re-dialing a dropped peer.
///
/// `next()` returns nil once the cumulative wall clock exceeds `giveUpAfter`.
/// Callers reset the policy after a successful reconnect.
struct LANReconnectPolicy {

    private let schedule: [TimeInterval]
    private let giveUpAfter: TimeInterval

    private var attempt = 0
    private var firstFailureAt: Date?

    static let `default` = LANReconnectPolicy(
        schedule: [1, 2, 4, 8, 16],
        giveUpAfter: 30
    )

    init(schedule: [TimeInterval], giveUpAfter: TimeInterval) {
        self.schedule = schedule
        self.giveUpAfter = giveUpAfter
    }

    mutating func next() -> TimeInterval? {
        let now = Date()
        if firstFailureAt == nil {
            firstFailureAt = now
        }
        if let start = firstFailureAt, now.timeIntervalSince(start) > giveUpAfter {
            return nil
        }
        let delay = schedule[min(attempt, schedule.count - 1)]
        attempt += 1
        return delay
    }

    mutating func reset() {
        attempt = 0
        firstFailureAt = nil
    }
}
