//
//  DeliveryScorer.swift
//  Tompero
//
//  Pure scoring math extracted from GameScene.makeDelivery so the success
//  / failure decision and the difficulty multiplier can be unit-tested
//  without spinning up an SKScene. Side effects (SFX, network sends,
//  match-statistics mutation) stay in GameScene.
//

import Foundation

struct DeliveryOutcome: Equatable {
    /// True when the delivered plate matched one of the active orders.
    let success: Bool
    /// Score awarded for this delivery (0 on failure).
    let coinsAdded: Int
    /// Index into the input `orders` of the matched order, or nil on failure.
    /// GameScene uses this to remove the order from its queue.
    let matchedOrderIndex: Int?
}

enum DeliveryScorer {

    /// Pick the first matching order (if any), apply the difficulty multiplier,
    /// and return whether the delivery succeeds plus the coins awarded.
    static func score(
        plate: Plate,
        against orders: [Order],
        difficulty: GameDifficulty
    ) -> DeliveryOutcome {
        guard let index = orders.firstIndex(where: { $0.isEquivalent(to: plate) }) else {
            return DeliveryOutcome(success: false, coinsAdded: 0, matchedOrderIndex: nil)
        }
        let multiplier = bonus(for: difficulty)
        return DeliveryOutcome(
            success: true,
            coinsAdded: orders[index].score * multiplier,
            matchedOrderIndex: index
        )
    }

    static func bonus(for difficulty: GameDifficulty) -> Int {
        switch difficulty {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }
}
