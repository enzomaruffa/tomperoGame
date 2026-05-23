//
//  MainCoordinator.swift
//  Tompero
//
//  Created by akira tsukamoto on 27/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import UIKit

class MainCoordinator: Coordinator {
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        navigationController.setNavigationBarHidden(true, animated: false)
    }
    
    func start() {
        initial()
    }
    
    func popToRoot() {
        navigationController.popToRootViewController(animated: true)
    }
    
    // Returns if a view controller is on top
    func isOnTop(controller: UIViewController?) -> Bool {
        return navigationController.viewControllers.last == controller
    }
    
    func initial() {
        let controller = InicialViewController.instantiate()
        controller.coordinator = self
        navigationController.pushViewController(controller, animated: false)
    }
    
    func settings() {
        let controller = SettingsViewController.instantiate()
        controller.coordinator = self
        navigationController.pushViewController(controller, animated: true)
    }
    
    func video() {
        let controller = CutsceneViewController.instantiate()
        controller.coordinator = self
        navigationController.pushViewController(controller, animated: true)
    }
    
    func menu() {
        let controller = MenuCollectionViewController.instantiate()
        controller.coordinator = self
        navigationController.pushViewController(controller, animated: true)
    }
    
    func waitingRoom(hosting: Bool) {
        let controller = WaitingRoomViewController.instantiate()
        controller.coordinator = self
        controller.hosting = hosting
        navigationController.pushViewController(controller, animated: true)
    }
    
    func game(rule: GameRule, hosting: Bool) {
        let controller = GameViewController.instantiate()
        controller.coordinator = self
        controller.hosting = hosting
        controller.rule = rule
        navigationController.pushViewController(controller, animated: true)
    }
    
    func statistics(statistics: MatchStatistics) {
        let controller = StatisticsViewController.instantiate()
        controller.coordinator = self
        controller.statistics = statistics
        navigationController.pushViewController(controller, animated: false)
    }
    
}
