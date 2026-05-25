//
//  AwardComputer.swift
//  Tompero
//
//  Pure function that maps per-player action tallies to a single fun
//  title per player. Used by the post-match StatisticsView to celebrate
//  what each player actually did this match.
//
//  Ranking rule: each player gets the category they personally led in
//  (with a strictly positive count). Ties resolve alphabetically by
//  player name. Players who didn't lead any category fall back to a
//  generic "Sous Chef" so nobody leaves with no title.
//

import Foundation

struct PlayerAward: Equatable {
    let title: String
    let supportingValue: Int
    /// Short descriptor of what the supportingValue represents — used in
    /// the StatisticsView card under the title.
    let detail: String
}

enum AwardComputer {

    private struct Category {
        let title: String
        let detail: (Int) -> String
        let metric: (PlayerAwardStats) -> Int
    }

    /// Ordered so a player who leads ties between two categories takes the
    /// earlier one. Order roughly maps "most defining" first.
    private static let categories: [Category] = [
        Category(
            title: "The Delivery Guy",
            detail: { "\($0) deliveries" },
            metric: { $0.ordersDelivered }
        ),
        Category(
            title: "Chop Chop",
            detail: { "\($0) chops" },
            metric: { $0.chopActions }
        ),
        Category(
            title: "Hot Stuff",
            detail: { "\($0) cooks" },
            metric: { $0.cookActions }
        ),
        Category(
            title: "Fry Master",
            detail: { "\($0) fries" },
            metric: { $0.fryActions }
        ),
        Category(
            title: "Pipeline Pro",
            detail: { "\($0) pipe sends" },
            metric: { $0.pipeForwards }
        ),
        Category(
            title: "Plate Boss",
            detail: { "\($0) plates" },
            metric: { $0.platesCreated }
        )
    ]

    private static let fallback = PlayerAward(
        title: "Sous Chef",
        supportingValue: 0,
        detail: "helped out"
    )

    /// Compute one award per player from the full per-player stats dict.
    /// Each category's winner takes that category's title; ties resolve
    /// alphabetically. Anyone left without a category gets "Sous Chef".
    static func compute(awards: [String: PlayerAwardStats]) -> [String: PlayerAward] {
        var result: [String: PlayerAward] = [:]
        var available = Set(categories.indices)

        // Process categories in declared order. For each, assign to the
        // player with the strictly-highest metric who doesn't already have
        // an award. Tied counts resolve by alphabetical player name.
        for (categoryIndex, category) in categories.enumerated() where available.contains(categoryIndex) {
            let unawarded = awards.filter { result[$0.key] == nil }
            guard !unawarded.isEmpty else { break }
            let sorted = unawarded.sorted { lhs, rhs in
                let lValue = category.metric(lhs.value)
                let rValue = category.metric(rhs.value)
                if lValue != rValue { return lValue > rValue }
                return lhs.key < rhs.key
            }
            guard let winner = sorted.first else { continue }
            let value = category.metric(winner.value)
            guard value > 0 else { continue } // Don't award a "best chopper" who never chopped
            result[winner.key] = PlayerAward(
                title: category.title,
                supportingValue: value,
                detail: category.detail(value)
            )
            available.remove(categoryIndex)
        }

        for player in awards.keys where result[player] == nil {
            result[player] = fallback
        }
        return result
    }
}
