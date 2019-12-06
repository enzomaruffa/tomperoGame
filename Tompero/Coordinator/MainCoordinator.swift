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
//        game(tables: [PlayerTable(type: .chopping, ingredient: nil),
//                      PlayerTable(type: .cooking, ingredient: nil),
//                      PlayerTable(type: .frying, ingredient: nil)], hosting: true)
        inicial()
//        testGameScene()
//        let tables: [String : [PlayerTable]] = [
//            "God" : [
//                PlayerTable(type: .chopping, ingredient: nil),
//                PlayerTable(type: .cooking, ingredient: nil),
//                PlayerTable(type: .frying, ingredient: nil)
//            ],
//            "Enzo's Enzo's iPhone" : [
//                PlayerTable(type: .chopping, ingredient: nil),
//                PlayerTable(type: .chopping, ingredient: nil),
//                PlayerTable(type: .chopping, ingredient: nil)
//            ],
//            "CU" : [
//                PlayerTable(type: .chopping, ingredient: nil),
//                PlayerTable(type: .chopping, ingredient: nil),
//                PlayerTable(type: .chopping, ingredient: nil)
//            ],
//            "CU 2" : [
//                PlayerTable(type: .chopping, ingredient: nil),
//                PlayerTable(type: .chopping, ingredient: nil),
//                PlayerTable(type: .chopping, ingredient: nil)
//            ]
//        ]
//        game(rule: GameRule(difficulty: .easy,
//                            possibleIngredients: [Tentacle(), MoonCheese(), Eyes(), Asteroid(), Tardigrades()],
//                            playerTables: tables,
//                            playerOrder: ["God", "Enzo's Enzo's iPhone", "CU", "CU 2"]),
//             hosting: true)
    }
    
    func testGameScene() {
        let controller = GameViewController.instantiate()
        controller.coordinator = self
        navigationController.pushViewController(controller, animated: false)
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
