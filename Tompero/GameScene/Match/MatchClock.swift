//
//  MatchClock.swift
//  Tompero
//
//  60-frame countdown wrapper that replaces the inline match timer logic in
//  GameScene. Decrements `timeRemaining` by 1.0 once every 60 ticks once
//  `start()` has been called, and fires `onWarning` exactly once when the
//  remaining time first drops below 15 seconds and `onTimesUp` exactly once
//  when it drops below 0.
//
//  The original GameScene used `< 15` and `< 0` (not `<=`), so the warning
//  fires on the tick that takes the timer from 15 → 14 and times-up fires
//  on the tick that takes it from 0 → -1. Replicating that off-by-one is
//  intentional — the audio cues are tuned to it.
//

import Foundation

final class MatchClock {

    /// Per-tick decrement. Matches the 60Hz update loop SpriteKit drives.
    private static let secondsPerTick: Float = 1.0 / 60.0

    /// Seconds of game time remaining. Goes negative — that's how times-up
    /// fires exactly once at the threshold-crossing tick.
    private(set) var timeRemaining: Float

    /// True once `start()` has been called. `tick()` is a no-op before then.
    private(set) var didStart: Bool = false

    /// Fires once on the tick that drives `timeRemaining` below 15.
    var onWarning: (() -> Void)?

    /// Fires once on the tick that drives `timeRemaining` below 0.
    var onTimesUp: (() -> Void)?

    /// Optional per-second callback for the HUD timer label. Fires the tick
    /// the integer second changes, not every frame.
    var onSecondElapsed: (() -> Void)?

    private var ticksSinceLastSecond: Int = 0
    private var warningFired: Bool = false
    private var timesUpFired: Bool = false

    init(initialSeconds: Float = 180) {
        self.timeRemaining = initialSeconds
    }

    func start() {
        didStart = true
    }

    func tick() {
        guard didStart else { return }

        ticksSinceLastSecond += 1
        if ticksSinceLastSecond >= 60 {
            timeRemaining -= 1
            ticksSinceLastSecond = 0
            onSecondElapsed?()
        }

        if !warningFired, timeRemaining < 15 {
            warningFired = true
            onWarning?()
        }

        if !timesUpFired, timeRemaining < 0 {
            timesUpFired = true
            onTimesUp?()
        }
    }
}
