//
//  GameCenterDashboard.swift
//  Tompero
//
//  SwiftUI wrapper around GKGameCenterViewController. GameKit only ships a
//  UIKit dashboard, so we present it as a sheet via UIViewControllerRepresentable.
//

import SwiftUI
import GameKit

struct GameCenterDashboard: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let vc = GKGameCenterViewController()
        vc.gameCenterDelegate = context.coordinator
        vc.viewState = .default
        return vc
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: { dismiss() })
    }

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let dismiss: () -> Void
        init(dismiss: @escaping () -> Void) {
            self.dismiss = dismiss
        }
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            dismiss()
        }
    }
}
