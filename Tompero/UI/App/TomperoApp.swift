//
//  TomperoApp.swift
//  Tompero
//
//  SwiftUI App lifecycle entry. Replaces the `@UIApplicationMain` AppDelegate +
//  SceneDelegate + Main.storyboard root the project shipped with for years.
//

import SwiftUI
import Firebase

@main
struct TomperoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
