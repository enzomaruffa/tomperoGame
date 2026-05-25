//
//  MatchNetworkAdapter.swift
//  Tompero
//
//  Owns the two Combine subscriptions that drive a match — game events
//  (plates, ingredients, orders, delivery notifications, statistics) and
//  matchmaking events (peer connection state). Each sink short-circuits
//  on `state.ended` so a late `.statistics` envelope after the host has
//  already declared the match over can't re-enter `endMatch` via the
//  scene's delegate.
//
//  GameScene used to embed both sink chains + a hand-written enum switch
//  per event. After this lands the scene just conforms to the delegate
//  protocol below and the boilerplate is gone.
//

import Combine
import Foundation

protocol MatchNetworkDelegate: AnyObject {
    func didReceivePlate(_ plate: Plate)
    func didReceiveIngredient(_ ingredient: Ingredient)
    func didReceiveOrders(_ orders: [Order])
    func didReceiveDelivery(_ notification: OrderDeliveryNotification)
    func didReceiveStatistics(_ statistics: MatchStatistics)
    func didReceivePeerUpdate(player: String, state: PeerConnectionState)
    func didReceivePauseRequest(paused: Bool)
    func didReceivePlayerAwards(player: String, stats: PlayerAwardStats)
}

final class MatchNetworkAdapter {

    private weak var delegate: MatchNetworkDelegate?
    private let state: MatchState
    private var cancellables = Set<AnyCancellable>()

    init(state: MatchState, delegate: MatchNetworkDelegate) {
        self.state = state
        self.delegate = delegate

        GameConnectionManager.shared.events
            .sink { [weak self] event in
                self?.handleGameEvent(event)
            }
            .store(in: &cancellables)

        LANConnectionManager.shared.matchmakingEvents
            .sink { [weak self] event in
                self?.handleMatchmakingEvent(event)
            }
            .store(in: &cancellables)
    }

    private func handleGameEvent(_ event: GameEvent) {
        guard let delegate else { return }

        // Awards are post-match signals — they MUST flow even after the
        // local `state.ended` flips, so peers can still slot their action
        // tallies into `MatchState.peerAwards` for the StatisticsView.
        if case .playerAwards(let player, let stats) = event {
            delegate.didReceivePlayerAwards(player: player, stats: stats)
            return
        }

        // Re-entry guard for all other events. The host calls `endMatch()`
        // synchronously when the clock fires `onTimesUp`, which broadcasts
        // a `.statistics` payload — the host's own loopback of that payload
        // would re-enter the delegate here if we didn't short-circuit.
        guard !state.ended else { return }
        switch event {
        case .plate(let plate):
            delegate.didReceivePlate(plate)
        case .ingredient(let ingredient):
            delegate.didReceiveIngredient(ingredient)
        case .orders(let orders):
            delegate.didReceiveOrders(orders)
        case .deliveryNotification(let notification):
            delegate.didReceiveDelivery(notification)
        case .statistics(let statistics):
            delegate.didReceiveStatistics(statistics)
        case .pauseRequest(let paused):
            delegate.didReceivePauseRequest(paused: paused)
        case .playerAwards:
            // Handled above the guard.
            break
        }
    }

    private func handleMatchmakingEvent(_ event: LANMatchmakingEvent) {
        // The reconnect overlay still needs to clean up after `state.ended`
        // (the match-end path pauses the scene but doesn't tear down the
        // overlay if a peer happens to be reconnecting). Forward peer state
        // unconditionally; the delegate ignores it post-end.
        guard let delegate else { return }
        if case .playerUpdate(let player, let state) = event {
            delegate.didReceivePeerUpdate(player: player, state: state)
        }
    }
}
