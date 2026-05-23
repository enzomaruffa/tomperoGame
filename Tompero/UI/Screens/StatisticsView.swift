//
//  StatisticsView.swift
//  Tompero
//
//  End-of-match summary. Pushed by the game container with the final
//  MatchStatistics; tapping MAIN MENU pops back to the root.
//

import SwiftUI
import GameKit

struct StatisticsView: View {
    let statistics: MatchStatistics

    @EnvironmentObject private var router: AppRouter

    var body: some View {
        ZStack {
            StarsBackground().ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Text("GAME OVER")
                    .font(.custom("TitilliumWeb-Bold", size: 64))
                    .foregroundColor(.white)

                VStack(spacing: 16) {
                    Text("\(statistics.totalDeliveredOrders) orders delivered!")
                        .font(.custom("TitilliumWeb-Bold", size: 36))
                        .foregroundColor(.white)
                    Text("\(statistics.totalPoints) coins earned!")
                        .font(.custom("TitilliumWeb-Bold", size: 36))
                        .foregroundColor(.white)
                }

                Spacer()

                Button {
                    EventLogger.shared.logButtonPress(buttonName: "statistics-menu")
                    router.popToRoot()
                } label: {
                    Text("MAIN MENU")
                        .font(.custom("TitilliumWeb-Bold", size: 32))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(Color.black.opacity(0.35))
                        .cornerRadius(16)
                }

                Spacer().frame(height: 32)
            }
            .padding()
        }
        .task {
            await submitStatisticsSideEffects()
        }
    }

    /// Fire-and-forget side effects that used to run in viewDidLoad.
    private func submitStatisticsSideEffects() async {
        EventLogger.shared.logCoinsInMatch(coins: statistics.totalPoints)
        CloudKitManager.shared.addNewMatch(
            withHash: statistics.matchHash,
            coinCount: statistics.totalPoints
        )
        submitScoreToGameCenter()
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
