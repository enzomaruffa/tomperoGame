//
//  AppRouter.swift
//  Tompero
//
//  Single source of truth for in-app navigation. Replaces MainCoordinator.
//

import SwiftUI

/// All screens the app can navigate to from the root. `GameRule` and
/// `MatchStatistics` are reference types (classes) without a value-level
/// identity, so Hashable / Equatable are implemented manually via
/// `ObjectIdentifier` — two destination instances compare equal only if they
/// reference the very same payload object.
enum AppDestination: Hashable {
    case settings
    case video
    case menu
    case waitingRoom(hosting: Bool)
    case game(rule: GameRule, hosting: Bool)
    case statistics(MatchStatistics)

    static func == (lhs: AppDestination, rhs: AppDestination) -> Bool {
        switch (lhs, rhs) {
        case (.settings, .settings), (.video, .video), (.menu, .menu):
            return true
        case (.waitingRoom(let a), .waitingRoom(let b)):
            return a == b
        case (.game(let aRule, let aHost), .game(let bRule, let bHost)):
            return aRule === bRule && aHost == bHost
        case (.statistics(let a), .statistics(let b)):
            return a === b
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .settings: hasher.combine(0)
        case .video: hasher.combine(1)
        case .menu: hasher.combine(2)
        case .waitingRoom(let hosting):
            hasher.combine(3)
            hasher.combine(hosting)
        case .game(let rule, let hosting):
            hasher.combine(4)
            hasher.combine(ObjectIdentifier(rule))
            hasher.combine(hosting)
        case .statistics(let stats):
            hasher.combine(5)
            hasher.combine(ObjectIdentifier(stats))
        }
    }
}

/// Holds the navigation stack's path. Injected via `@EnvironmentObject` to
/// every screen so any view can push / pop without owning a reference to the
/// previous one.
final class AppRouter: ObservableObject {
    @Published var path: [AppDestination] = []

    func push(_ destination: AppDestination) {
        withAnimation(.easeInOut(duration: 0.5)) {
            path.append(destination)
        }
    }

    func pop() {
        guard !path.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            path.removeLast()
        }
    }

    func popToRoot() {
        withAnimation(.easeInOut(duration: 0.5)) {
            path.removeAll()
        }
    }
}
