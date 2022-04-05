//
//  GameViewController.swift
//  Tompero
//
//  Created by Vinícius Binder on 22/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController, Storyboarded {
    
    static var storyboardName = "Game"
    weak var coordinator: MainCoordinator?
    
    var rule: GameRule?
    var hosting: Bool = false
    
    @IBOutlet weak var skView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = skView {
            if let scene = GameScene(fileNamed: "GameScene") {
                scene.rule = self.rule
                scene.hosting = self.hosting
                scene.coordinator = self.coordinator
                scene.controller = self
                
                // if iPad
                scene.scaleMode = traitCollection.verticalSizeClass == .regular ? .aspectFit : .aspectFill
                
                scene.backgroundColor = .clear
                view.allowsTransparency = true
                view.backgroundColor = .clear
                
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        GameConnectionManager.shared.removeAllObservers()
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
      return false
    }
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return UIRectEdge.all
    }
    
}
