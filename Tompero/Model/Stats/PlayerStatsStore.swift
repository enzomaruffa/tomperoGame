//
//  PlayerStatsStore.swift
//  Tompero
//
//  Lifetime player aggregates persisted in UserDefaults. Updated once per
//  match from `StatisticsView.task`. Read by `SettingsView.statsTab`.
//
//  Designed to be drop-in injectable for tests: pass a custom
//  `UserDefaults` suite via `init(defaults:)`. Production code uses
//  `PlayerStatsStore.shared`.
//

import Foundation

final class PlayerStatsStore {

    static let shared = PlayerStatsStore(defaults: .standard)

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    // MARK: - Aggregates

    var totalMatches: Int { defaults.integer(forKey: K.totalMatches) }
    var totalOrdersDelivered: Int { defaults.integer(forKey: K.ordersDelivered) }
    var totalOrdersGenerated: Int { defaults.integer(forKey: K.ordersGenerated) }
    var totalCoinsEarned: Int { defaults.integer(forKey: K.coinsEarned) }

    /// `Int` is `0` when never set, so default-zero is the right fallback for
    /// "no best yet" — any real match score must beat that.
    func bestScore(for difficulty: GameDifficulty) -> Int {
        defaults.integer(forKey: K.bestScore(for: difficulty))
    }

    var lifetimeActions: PlayerAwardStats {
        guard let data = defaults.data(forKey: K.lifetimeActions) else { return .zero }
        return (try? JSONDecoder().decode(PlayerAwardStats.self, from: data)) ?? .zero
    }

    /// Accuracy = delivered / generated. Returns nil when no orders have ever
    /// been generated so the UI can show a placeholder dash.
    var accuracy: Double? {
        let generated = totalOrdersGenerated
        guard generated > 0 else { return nil }
        return Double(totalOrdersDelivered) / Double(generated)
    }

    // MARK: - Record

    /// Fold one match's results into the lifetime aggregates. `localActions`
    /// is the per-action tally for the local player this match (Phase 8E
    /// tracks the counters during gameplay).
    func record(matchStatistics: MatchStatistics, localActions: PlayerAwardStats) {
        defaults.set(totalMatches + 1, forKey: K.totalMatches)
        defaults.set(totalOrdersDelivered + matchStatistics.totalDeliveredOrders, forKey: K.ordersDelivered)
        defaults.set(totalOrdersGenerated + matchStatistics.totalGeneratedOrders, forKey: K.ordersGenerated)
        defaults.set(totalCoinsEarned + matchStatistics.totalPoints, forKey: K.coinsEarned)

        let difficulty = matchStatistics.ruleUsed.difficulty
        let currentBest = bestScore(for: difficulty)
        if matchStatistics.totalPoints > currentBest {
            defaults.set(matchStatistics.totalPoints, forKey: K.bestScore(for: difficulty))
        }

        var actions = lifetimeActions
        actions.add(localActions)
        if let encoded = try? JSONEncoder().encode(actions) {
            defaults.set(encoded, forKey: K.lifetimeActions)
        }
    }

    /// Test affordance — wipes every key this store reads/writes.
    func reset() {
        for key in K.allKeys {
            defaults.removeObject(forKey: key)
        }
    }

    private enum K {
        static let totalMatches = "stats.totalMatches"
        static let ordersDelivered = "stats.ordersDelivered"
        static let ordersGenerated = "stats.ordersGenerated"
        static let coinsEarned = "stats.coinsEarned"
        static let lifetimeActions = "stats.lifetimeActions"

        static func bestScore(for difficulty: GameDifficulty) -> String {
            "stats.bestScore." + difficulty.rawValue
        }

        static let allKeys: [String] = [
            totalMatches, ordersDelivered, ordersGenerated, coinsEarned, lifetimeActions,
            bestScore(for: .easy), bestScore(for: .medium), bestScore(for: .hard)
        ]
    }
}
