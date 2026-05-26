//
//  RootView.swift
//  Tompero
//
//  Top-level SwiftUI scene. Owns the `AppRouter` and dispatches every
//  `AppDestination` to its concrete view. Once the lifecycle flip lands in
//  the final migration commit, `TomperoApp` will host this directly.
//

import SwiftUI

struct RootView: View {
    @StateObject private var router = AppRouter()

    private static let bodyTimer: Void = {
        Log.game.info("LAUNCH +\(AppDelegate.elapsed())s RootView first body")
    }()

    var body: some View {
        _ = Self.bodyTimer
        return NavigationStack(path: $router.path) {
            InicialView()
                .navigationBarHidden(true)
                .navigationDestination(for: AppDestination.self) { destination in
                    destinationView(for: destination)
                        .navigationBarHidden(true)
                }
        }
        .environmentObject(router)
        .onAppear(perform: applyUIPreviewRouteIfNeeded)
    }

    /// DEBUG-only: jump straight to a screen for screenshot verification.
    /// Driven by `SIMCTL_CHILD_UI_PREVIEW=lobby|game` so it never affects
    /// shipping builds. No-op unless the env var is set.
    private func applyUIPreviewRouteIfNeeded() {
        #if DEBUG
        guard let preview = ProcessInfo.processInfo.environment["UI_PREVIEW"] else { return }
        switch preview {
        case "lobby":
            router.push(.waitingRoom(hosting: true))
        case "game":
            // Real lobbies always hand off a 4-slot list (padded with
            // "__empty__"); the pipe setup indexes playerOrder[1...3].
            let rule = GameRuleFactory.generateRule(
                difficulty: .medium,
                players: ["You", "Bot", "__empty__", "__empty__"]
            )
            router.push(.game(rule: rule, hosting: true))
        default:
            break
        }
        #endif
    }

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .settings:
            SettingsView()
        case .video:
            CutsceneView()
        case .menu:
            MenuView()
        case .waitingRoom(let hosting):
            WaitingRoomView(hosting: hosting)
        case .game(let rule, let hosting):
            GameContainerView(rule: rule, hosting: hosting)
        case .statistics(let stats, let localActions, let peerAwards):
            StatisticsView(statistics: stats, localActions: localActions, peerAwards: peerAwards)
        }
    }
}
