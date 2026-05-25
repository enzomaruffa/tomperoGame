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

    /// Wall-clock at process start. Used to log "X.X s since launch" markers
    /// at suspected hotspots so we can see what's actually slow in the field.
    static let launchClock = Date()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Log.game.info("LAUNCH +\(Self.elapsed())s AppDelegate.didFinishLaunching enter")

        // Firebase's own initialization can run on the main thread, but its
        // *Installations* subsystem retries on keychain failures (unsigned
        // simulator builds), so launches behind a missing entitlement can
        // hang main for tens of seconds. Defer to a background queue — we
        // get the same eventual subsystem availability, just not blocking
        // SwiftUI's first frame.
        DispatchQueue.global(qos: .utility).async {
            FirebaseApp.configure()
            Log.game.info("LAUNCH +\(Self.elapsed())s FirebaseApp.configure done")
        }

        MusicPlayer.shared.loadData()
        Log.game.info("LAUNCH +\(Self.elapsed())s AppDelegate.didFinishLaunching exit")
        return true
    }

    static func elapsed() -> String {
        String(format: "%.2f", Date().timeIntervalSince(launchClock))
    }
}
