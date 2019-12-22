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
        var gameSceneTest: Bool = true
        
        #if !DEBUG
            gameSceneTest = false
        #endif
        
        if gameSceneTest {
            let tables: [String : [PlayerTable]] = [
                "God" : [
                    PlayerTable(type: .frying, ingredient: nil),
                    PlayerTable(type: .plate, ingredient: nil),
                    PlayerTable(type: .ingredient, ingredient: Asteroid())
                ],
                "Enzo's Enzo's iPhone" : [
                    PlayerTable(type: .chopping, ingredient: nil),
                    PlayerTable(type: .chopping, ingredient: nil),
                    PlayerTable(type: .chopping, ingredient: nil)
                ],
                "CU" : [
                    PlayerTable(type: .chopping, ingredient: nil),
                    PlayerTable(type: .chopping, ingredient: nil),
                    PlayerTable(type: .chopping, ingredient: nil)
                ],
                "CU 2" : [
                    PlayerTable(type: .chopping, ingredient: nil),
                    PlayerTable(type: .chopping, ingredient: nil),
                    PlayerTable(type: .chopping, ingredient: nil)
                ]
            ]
            
//            statistics(statistics: MatchStatistics(ruleUsed: GameRule(
//                difficulty: .hard,
//                possibleIngredients: [
//                    Asteroid(),
//                    Tentacle(),
//                    MoonCheese(),
//                    Eyes(),
//                    Tardigrades()
//                ],
//                playerTables: tables,
//                playerOrder: [
//                    "God",
//                    "Enzo's Enzo's iPhone",
//                    "CU",
//                    "CU 2"]
//            )))
            
            game(
                rule: GameRule(
                    difficulty: .easy,
                    possibleIngredients: [
                        Asteroid(),
                        Tentacle(),
                        MoonCheese(),
                        Eyes(),
                        Tardigrades()
                    ],
                    playerTables: tables,
                    playerOrder: [
                        "God",
                        "Enzo's Enzo's iPhone",
                        "__empty__",
                        "__empty__"]
                ),
                hosting: true
            )
            return
        }
        
        inicial()
    }
    
    func popToRoot() {
        navigationController.popToRootViewController(animated: true)
    }
        
    func inicial() {
        let controller = InicialViewController.instantiate()
        controller.coordinator = self
        navigationController.pushViewController(controller, animated: false)
    }
    
    func menu() {
        let controller = MenuCollectionViewController.instantiate()
        controller.coordinator = self
        controller.modalTransitionStyle = .crossDissolve
//        navigationController.present(controller, animated: true, completion: nil)
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
    
    func statistics(statistics: MatchStatistics) {
        let controller = StatisticsViewController.instantiate()
        controller.coordinator = self
        controller.statistics = statistics
        navigationController.pushViewController(controller, animated: false)
    }
    
}
