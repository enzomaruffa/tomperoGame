//
//  PlayerAwardStats.swift
//  Tompero
//
//  Per-player per-match action tally. Sent over the wire at match end so
//  every device can compute the same set of awards (see `AwardComputer`).
//  Also folded into `PlayerStatsStore`'s lifetime aggregates so the
//  Settings → Stats tab can show what kind of cook the player is.
//

import Foundation

struct PlayerAwardStats: Codable, Equatable {
    var ordersDelivered: Int = 0
    var chopActions: Int = 0
    var cookActions: Int = 0
    var fryActions: Int = 0
    var platesCreated: Int = 0
    var pipeForwards: Int = 0

    static let zero = PlayerAwardStats()

    mutating func add(_ other: PlayerAwardStats) {
        ordersDelivered += other.ordersDelivered
        chopActions += other.chopActions
        cookActions += other.cookActions
        fryActions += other.fryActions
        platesCreated += other.platesCreated
        pipeForwards += other.pipeForwards
    }
}
