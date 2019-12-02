//
//  LevelViewController.swift
//  Tompero
//
//  Created by akira tsukamoto on 01/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import UIKit

class LevelViewController:UIViewController, Storyboarded {
    
    // MARK: - Variables
    static var storyboardName = "Level"
    weak var coordinator: MainCoordinator?
    
    // MARK: - Outlets
    @IBOutlet weak var easy: UIButton!
    @IBOutlet weak var medium: UIButton!
    @IBOutlet weak var hard: UIButton!
    
    // MARK: - Actions
    
    @IBAction func easyButton(_ sender: Any) {
        
        let vcs = WaitingRoomViewController()
        vcs.level.setTitle("EASY", for: .normal)
        coordinator?.waitingRoom(hosting: true)
    }
    
    @IBAction func mediumButton(_ sender: Any) {
        let vcs = WaitingRoomViewController()
        print("TITULO BUGADASSSSU : ",vcs.level.currentTitle)
        //vcs.level.setTitle("MEDIUM", for: .normal)
        coordinator?.waitingRoom(hosting: true)
    }
    
    @IBAction func hardButton(_ sender: Any) {
        let vcs = WaitingRoomViewController()
        vcs.level.setTitle("HARD", for: .normal)
        coordinator?.waitingRoom(hosting: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    
    
    
}
