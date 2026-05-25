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
        case .statistics(let stats):
            StatisticsView(statistics: stats)
        }
    }
}
