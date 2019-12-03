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
    
    func game(tables: [PlayerTable], hosting: Bool) {
        guard tables.count == 3 else { return }
        
        let controller = GameViewController.instantiate()
        controller.coordinator = self
        controller.hosting = hosting
        controller.tables = tables
        navigationController.pushViewController(controller, animated: false)
    }
}
