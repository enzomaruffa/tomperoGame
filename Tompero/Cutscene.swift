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

// swiftlint:disable force_cast
class Cutscene: SKScene {

    // MARK: - Coordinator
    weak var coordinator: MainCoordinator?
    
    var player: AVPlayer!
    var videoSprite: SKVideoNode!

    //var videoNode: SKVideoNode
    let videoDuration = 106
    
    var ticks = 0
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        let videoURL: NSURL = Bundle.main.url(forResource: "videoIntro", withExtension: "mp4")! as NSURL
        videoSprite = SKVideoNode(url: videoURL as URL)
        self.addChild(videoSprite)
        
        let videoSize = CGSize(width: 3840, height: 2160)
        
        var currentViewSize = self.viewSizeInLocalCoordinates()
        
        let requiredScale = max(videoSize.width / currentViewSize.width, videoSize.height / currentViewSize.height)
        
        let cameraNode = SKCameraNode()
        self.camera = cameraNode
        self.scene?.addChild(cameraNode)
        
        self.camera?.setScale(requiredScale)
        
        videoSprite.play()
    }
    
    override func update(_ currentTime: TimeInterval) {
        ticks += 1
        
        if ticks == videoDuration * 60 {
            videoSprite.removeFromParent()
            videoSprite.pause()
            coordinator?.inicial()
        }
        
        
    }
}
