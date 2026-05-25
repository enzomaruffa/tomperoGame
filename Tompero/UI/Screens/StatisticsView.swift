//
//  StatisticsView.swift
//  Tompero
//
//  End-of-match summary. Layout matches the original Statistics.storyboard:
//  WR_bgFront base, GameOver_detail flanking overlays, and a central
//  GameOver_box panel with title, orders, coins, and MAIN MENU button.
//
//  Bottom half reveals per-player awards/titles after a brief delay so the
//  big numbers land first.
//

import Combine
import SwiftUI
import GameKit

struct StatisticsView: View {
    let statistics: MatchStatistics
    /// Per-action tally the local player accumulated this match. Defaults to
    /// zero so callers that haven't wired up the in-game tracker yet still
    /// compile; populated by `GameContainerView` via the scene's `state.myActions`.
    var localActions: PlayerAwardStats = .zero
    /// Per-player tallies received over the wire while the scene was still
    /// live. Late arrivals are folded in via a Combine sink below.
    var peerAwards: [String: PlayerAwardStats] = [:]

    @EnvironmentObject private var router: AppRouter

    @State private var awards: [String: PlayerAward] = [:]
    @State private var awardsRevealed: Bool = false
    @State private var awardsCancellable: AnyCancellable?

    private var localPlayer: String { LANConnectionManager.shared.selfName }

    private var realPlayerOrder: [String] {
        statistics.ruleUsed.playerOrder.filter { $0 != "__empty__" }
    }

    var body: some View {
        DesignCanvas { scale in
            // Flanking decorative panels
            Image("GameOver_detailLeft")
                .resizable()
                .scaledToFit()
                .designed(x: 0, y: 0, w: 213, h: 414, scale: scale)
            Image("GameOver_detailRight")
                .resizable()
                .scaledToFit()
                .designed(x: 683, y: 0, w: 213, h: 414, scale: scale)

            Image("GameOver_box")
                .resizable()
                .scaledToFit()
                .designed(x: 181, y: 63.5, w: 534, h: 266, scale: scale)

            Text("GAME OVER")
                .font(.custom("TitilliumWeb-Bold", size: 32 * scale))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .designed(x: 194.5, y: 68, w: 520.5, h: 36, scale: scale)

            VStack(spacing: 2 * scale) {
                Text("\(statistics.totalDeliveredOrders) orders delivered!")
                    .font(.custom("TitilliumWeb-Bold", size: 20 * scale))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("\(statistics.totalPoints) coins earned!")
                    .font(.custom("TitilliumWeb-Bold", size: 20 * scale))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .designed(x: 194.5, y: 102, w: 520.5, h: 56, scale: scale)

            // Awards strip — fades in once we've collected awards for every
            // real player (or the 2.5s timeout fires).
            AwardsStrip(awards: awards, players: realPlayerOrder, localPlayer: localPlayer, scale: scale)
                .opacity(awardsRevealed ? 1 : 0)
                .animation(.easeInOut(duration: 0.4), value: awardsRevealed)
                .designed(x: 194.5, y: 158, w: 520.5, h: 60, scale: scale)

            Button {
                EventLogger.shared.logButtonPress(buttonName: "statistics-menu")
                router.popToRoot()
            } label: {
                Text("MAIN MENU")
                    .font(.custom("TitilliumWeb-Bold", size: 22 * scale))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(12 * scale)
            }
            .buttonStyle(PressableButtonStyle())
            .designed(x: 334, y: 229.5, w: 241, h: 47, scale: scale)
        }
        .task {
            EventLogger.shared.logCoinsInMatch(coins: statistics.totalPoints)
            PlayerStatsStore.shared.record(matchStatistics: statistics, localActions: localActions)
            await CloudKitManager.shared.addNewMatch(
                withHash: statistics.matchHash,
                coinCount: statistics.totalPoints
            )
            submitScoreToGameCenter()
        }
        .task {
            // Subscribe to late-arriving award payloads (case where the
            // statistics view mounted before a peer's broadcast landed).
            // Bootstrap with what the scene already collected.
            var collected = peerAwards
            collected[localPlayer] = localActions
            tryReveal(collected: collected)

            awardsCancellable = GameConnectionManager.shared.events
                .receive(on: DispatchQueue.main)
                .sink { event in
                    if case .playerAwards(let player, let stats) = event {
                        collected[player] = stats
                        tryReveal(collected: collected)
                    }
                }

            // Hard cap: reveal whatever we have after 2.5s even if not
            // every player chimed in.
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            tryReveal(collected: collected, force: true)
        }
    }

    private func tryReveal(collected: [String: PlayerAwardStats], force: Bool = false) {
        let everyoneArrived = realPlayerOrder.allSatisfy { collected[$0] != nil }
        guard force || everyoneArrived else { return }
        guard !awardsRevealed else { return }
        awards = AwardComputer.compute(awards: collected)
        awardsRevealed = true
        awardsCancellable?.cancel()
        awardsCancellable = nil
    }

    private func submitScoreToGameCenter() {
        let leaderboardID: String
        switch statistics.ruleUsed.difficulty {
        case .easy: leaderboardID = "com.spacespice.easy"
        case .medium: leaderboardID = "com.spacespice.medium"
        case .hard: leaderboardID = "com.spacespice.hard"
        }
        GKLeaderboard.submitScore(
            statistics.totalPoints,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardID]
        ) { error in
            if let error {
                Log.game.error("\(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

private struct AwardsStrip: View {
    let awards: [String: PlayerAward]
    let players: [String]
    let localPlayer: String
    let scale: CGFloat

    var body: some View {
        HStack(spacing: 6 * scale) {
            ForEach(players, id: \.self) { player in
                AwardCard(
                    playerName: player == localPlayer ? "You" : shortened(player),
                    award: awards[player],
                    isLocal: player == localPlayer,
                    scale: scale
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Lobby display names often include a Bonjour suffix; show the first
    /// word so the card stays compact.
    private func shortened(_ name: String) -> String {
        name.components(separatedBy: " ").first ?? name
    }
}

private struct AwardCard: View {
    let playerName: String
    let award: PlayerAward?
    let isLocal: Bool
    let scale: CGFloat

    var body: some View {
        VStack(spacing: 2 * scale) {
            Text(playerName)
                .font(.custom("TitilliumWeb-Bold", size: 11 * scale))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(award?.title ?? "—")
                .font(.custom("TitilliumWeb-Bold", size: 13 * scale))
                .foregroundColor(.yellow)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(award?.detail ?? "")
                .font(.custom("TitilliumWeb-Light", size: 9 * scale))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.vertical, 4 * scale)
        .padding(.horizontal, 6 * scale)
        .frame(maxWidth: .infinity)
        .background(isLocal ? Color.white.opacity(0.22) : Color.white.opacity(0.10))
        .cornerRadius(6 * scale)
    }
}
