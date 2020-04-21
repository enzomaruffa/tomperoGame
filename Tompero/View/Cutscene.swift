//
//  Cutscene.swift
//  Tompero
//
//  Created by akira tsukamoto on 12/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit
import UIKit
import AVFoundation

enum State {
    case hide
    case show
}

// swiftlint:disable force_cast
class Cutscene: SKScene {
    
    // MARK: - Coordinator
    weak var coordinator: MainCoordinator?
    
    var player: AVPlayer!
    var videoSprite: SKVideoNode!
    //var videoNode: SKVideoNode
    let videoDuration = 106
    
    var button: SKNode! = nil
    var buttonAcativated: Bool = true
    
    var ticks = 0
    var ticksButton = 0
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        let videoURL: NSURL = Bundle.main.url(forResource: "videoIntro", withExtension: "mp4")! as NSURL
        videoSprite = SKVideoNode(url: videoURL as URL)
        self.addChild(videoSprite)
        
        let videoSize = CGSize(width: 3840, height: 2160)
        
        let currentViewSize = self.viewSizeInLocalCoordinates()
        
        let requiredScale = max(videoSize.width / currentViewSize.width, videoSize.height / currentViewSize.height)
        
        createExitButton()
        
        let cameraNode = SKCameraNode()
        self.camera = cameraNode
        self.scene?.addChild(cameraNode)
        
        self.camera?.setScale(requiredScale)
        
        videoSprite.play()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchLocation = touch!.location(in: self)
        print(button.zPosition)
        // Check if the location of the touch is within the button's bounds
        if (self.scene?.contains(touchLocation))! {
            if buttonAcativated {
                hideOrShowCloseButton(state: .hide)
            } else {
                hideOrShowCloseButton(state: .show)
            }
        }
        
        if button.contains(touchLocation) && !buttonAcativated {
            videoSprite.pause()
            coordinator?.initial()
        }
    }
    
    func createExitButton() {
        // Create a simple red rectangle that's 100x44
        button = SKSpriteNode(color: SKColor.red, size: CGSize(width: 300, height: 300))
        // Put it in the center of the scene
        button.position = CGPoint(x:-self.frame.width/2.5, y:+self.frame.height/2.5)
        self.addChild(button)
    }
    
    func hideOrShowCloseButton(state: State) {
        if state == .hide {
            button.run(SKAction.fadeOut(withDuration: 0.5))
            buttonAcativated = false
            ticksButton = 0
        } else if state == .show {
            button.alpha = 1
            buttonAcativated = true
            
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        ticks += 1
        
        if buttonAcativated {
            ticksButton += 1
            if ticksButton == 3*60 {
                hideOrShowCloseButton(state: .hide)
            }
        }
        
        if ticks == videoDuration * 60 {
            videoSprite.removeFromParent()
            videoSprite.pause()
            coordinator?.popToRoot()
        }
    }
}
