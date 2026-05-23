//
//  AppDelegate.swift
//  Tompero
//
//  Scoped to app-wide bootstrap that SwiftUI doesn't directly own:
//  Firebase + MusicPlayer warmup. Hosted by SwiftUI's
//  `UIApplicationDelegateAdaptor` in `TomperoApp`.
//

import UIKit
import Firebase

final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        MusicPlayer.shared.loadData()
        return true
    }
}
