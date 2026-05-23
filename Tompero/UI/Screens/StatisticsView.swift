//
//  StatisticsView.swift
//  Tompero
//
//  End-of-match summary. Layout matches the original Statistics.storyboard:
//  WR_bgFront base, GameOver_detail flanking overlays, and a central
//  GameOver_box panel with title, orders, coins, and MAIN MENU button.
//

import SwiftUI
import GameKit

struct StatisticsView: View {
    let statistics: MatchStatistics

    @EnvironmentObject private var router: AppRouter

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

            // Central box with title + stats + button (storyboard inner frame
            // at (181, 63.5, 534, 266); we add 181 to x and 63.5 to y for
            // each inner child).
            Image("GameOver_box")
                .resizable()
                .scaledToFit()
                .designed(x: 181, y: 63.5, w: 534, h: 266, scale: scale)

            Text("GAME OVER")
                .font(.custom("TitilliumWeb-Bold", size: 36 * scale))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .designed(x: 194.5, y: 68, w: 520.5, h: 45.5, scale: scale)

            Text("\(statistics.totalDeliveredOrders) orders delivered!")
                .font(.custom("TitilliumWeb-Bold", size: 24 * scale))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .designed(x: 349, y: 113.5, w: 211, h: 74, scale: scale)

            Text("\(statistics.totalPoints) coins earned!")
                .font(.custom("TitilliumWeb-Bold", size: 24 * scale))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .designed(x: 369.5, y: 147.5, w: 170.5, h: 74.5, scale: scale)

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
            .buttonStyle(.plain)
            .designed(x: 334, y: 229.5, w: 241, h: 47, scale: scale)
        }
        .task {
            EventLogger.shared.logCoinsInMatch(coins: statistics.totalPoints)
            CloudKitManager.shared.addNewMatch(
                withHash: statistics.matchHash,
                coinCount: statistics.totalPoints
            )
            submitScoreToGameCenter()
        }
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
