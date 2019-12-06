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
        // Debug waiting room or whole game
        inicial()
        
        // Debug game screen single
//        let tables: [String : [PlayerTable]] = [
//            MCManager.shared.selfName : [
//                PlayerTable(type: .chopping, ingredient: nil),
//                PlayerTable(type: .frying, ingredient: nil),
//                PlayerTable(type: .cooking, ingredient: nil)
//            ]
//        ]
//        game(rule: GameRule(difficulty: .easy,
//                            possibleIngredients: [Tentacle(), MoonCheese(), Eyes(), Asteroid(), Tardigrades()],
//                            playerTables: tables,
//                            playerOrder: [MCManager.shared.selfName]),
//             hosting: true)
    }
    
    func inicial() {
        let controller = InicialViewController.instantiate()
        controller.coordinator = self
        navigationController.pushViewController(controller, animated: false)
    }
    
    func menu() {
        let controller = MenuCollectionViewController.instantiate()
        controller.coordinator = self
        navigationController.pushViewController(controller, animated: false)
    }
    
    func waitingRoom(hosting: Bool) {
        let controller = WaitingRoomViewController.instantiate()
        controller.coordinator = self
        controller.hosting = hosting
        navigationController.pushViewController(controller, animated: false)
    }
    
    func game(rule: GameRule, hosting: Bool) {
        let controller = GameViewController.instantiate()
        controller.coordinator = self
        controller.hosting = hosting
        controller.rule = rule
        navigationController.pushViewController(controller, animated: false)
    }
}
