//
//  SceneDelegate.swift
//  Tompero
//
//  Hosts the window and the root navigation controller for the foreground
//  scene. Replaces the legacy AppDelegate-only window setup so we adopt the
//  UIScene lifecycle Apple has been warning about.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var coordinator: MainCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let navController = NavigationController()
        coordinator = MainCoordinator(navigationController: navController)
        coordinator?.start()

        let newWindow = UIWindow(windowScene: windowScene)
        newWindow.rootViewController = navController
        newWindow.makeKeyAndVisible()
        window = newWindow
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
