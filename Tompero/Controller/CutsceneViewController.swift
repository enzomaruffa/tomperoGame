//
//  CutsceneViewController.swift
//  Tompero
//
//  Created by akira tsukamoto on 12/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class CutsceneViewController: UIViewController, Storyboarded {
    
    static var storyboardName = "Cutscene"
    weak var coordinator: MainCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            if let scene = Cutscene(fileNamed: "Cutscene") {
                scene.coordinator = self.coordinator
                
                scene.scaleMode = .aspectFit
                
                scene.backgroundColor = .black
                
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
        }

    }
}
