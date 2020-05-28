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
//        let gsTest = false
//
//        #if !DEGUB
//        initial()
//        #else
//        gsTest ? gameSceneTest() : initial()
//        #endif
        
        gameSceneTest()
//        initial()
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
    
    // MARK: - Testing functions
    
    fileprivate func gameSceneTest() {
        let tables: [String : [PlayerTable]] = [
            MCManager.shared.selfName : [
                PlayerTable(type: .chopping, ingredient: nil),
                PlayerTable(type: .cooking, ingredient: nil),
                PlayerTable(type: .ingredient, ingredient: Tentacle())
            ],
            "alo" : [
                PlayerTable(type: .chopping, ingredient: nil),
                PlayerTable(type: .chopping, ingredient: nil),
                PlayerTable(type: .chopping, ingredient: nil)
            ],
            "alo 2" : [
                PlayerTable(type: .chopping, ingredient: nil),
                PlayerTable(type: .chopping, ingredient: nil),
                PlayerTable(type: .chopping, ingredient: nil)
            ],
            "__empty__" : [
                PlayerTable(type: .chopping, ingredient: nil),
                PlayerTable(type: .chopping, ingredient: nil),
                PlayerTable(type: .chopping, ingredient: nil)
            ]
        ]
        
        game(
            rule: GameRule(
                difficulty: .hard,
                possibleIngredients: [
                    Asteroid(),
                    Tentacle(),
                    MoonCheese(),
                    Eyes(),
                    Tardigrades()
                ],
                playerTables: tables,
                playerOrder: [
                    MCManager.shared.selfName,
                    "Enzo's Enzo's iPhone",
                    "God",
                    "__empty__"]
            ),
            hosting: true
        )
    }
    
    fileprivate func statisticsTest() {
        let tables: [String : [PlayerTable]] = [
            "God" : [
                PlayerTable(type: .frying, ingredient: nil),
                PlayerTable(type: .plate, ingredient: nil),
                PlayerTable(type: .ingredient, ingredient: Tentacle())
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
        
        let stats = MatchStatistics(ruleUsed: GameRule(
            difficulty: .hard,
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
                "CU",
                "CU 2"]
        ))
        
        statistics(statistics: stats)
        
        //         let stats2 = MatchStatistics(ruleUsed: GameRule(
        //                           difficulty: .easy,
        //                           possibleIngredients: [
        //                               Asteroid(),
        //                               Tentacle(),
        //                               MoonCheese(),
        //                               Eyes(),
        //                               Tardigrades()
        //                           ],
        //                           playerTables: tables,
        //                           playerOrder: [
        //                               "God",
        //                               "Enzo's Enzo's iPhone",
        //                               "CU",
        //                               "CU 2"]
        //                       ))
        
        //        print(stats.matchHash)
        
        //        let dbManager = CloudKitManager.shared
        //        dbManager.addNewMatch(withHash: stats.matchHash, coinCount: stats.totalPoints)
        //
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        //            dbManager.checkMatchExists(hash: stats.matchHash) { (result) in
        //                print("Match with hash \(stats.matchHash) exists? \(result)")
        //            }
        //
        //            dbManager.checkMatchExists(hash: "2143123213") { (result) in
        //                print("Match with hash 2143123213 exists? \(result)")
        //            }
        //
        //            dbManager.checkMatchExists(hash: stats2.matchHash) { (result) in
        //                print("Match with hash \(stats2.matchHash) exists? \(result)")
        //            } 
    }
    
}
