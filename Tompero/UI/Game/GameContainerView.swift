//
//  GameContainerView.swift
//  Tompero
//
//  SwiftUI wrapper around the UIKit-hosted GameViewController, which runs
//  the SpriteKit GameScene. Translates the SKScene's callback hooks
//  (`onMatchEnd`, `onMatchError`) into router actions.
//

import SwiftUI

struct GameContainerView: View {
    let rule: GameRule
    let hosting: Bool

    @EnvironmentObject private var router: AppRouter

    var body: some View {
        GameRepresentable(rule: rule, hosting: hosting) { statistics in
            router.push(.statistics(statistics))
        } onError: {
            router.popToRoot()
        }
        .ignoresSafeArea()
    }
}

private struct GameRepresentable: UIViewControllerRepresentable {
    let rule: GameRule
    let hosting: Bool
    let onMatchEnd: (MatchStatistics) -> Void
    let onError: () -> Void

    func makeUIViewController(context: Context) -> GameViewController {
        let vc = GameViewController()
        vc.rule = rule
        vc.hosting = hosting
        vc.onMatchEnd = onMatchEnd
        vc.onMatchError = onError
        return vc
    }

    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {}
}
