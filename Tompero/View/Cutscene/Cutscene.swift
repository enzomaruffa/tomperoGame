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
    
    // MARK: - Variables
    var player: AVPlayer!
    
    var videoNode: SKVideoNode!
    var videoDuration: Double! //seconds
    
    var backButton: SKSpriteNode!
    var backActive: Bool = true
    
    var videoNodeSize: CGSize!
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        let videoURL = Bundle.main.url(forResource: "videoIntro", withExtension: "mp4")!
        let videoAsset = AVURLAsset(url: videoURL)
        videoDuration = videoAsset.duration.seconds
        
        let video = videoAsset.tracks(withMediaType: AVMediaType.video).first!
        let videoSize = video.naturalSize.applying(video.preferredTransform)
        
        let currentViewSize = viewSizeInLocalCoordinates()
        
        let requiredScale = max(videoSize.width / currentViewSize.width, videoSize.height / currentViewSize.height)
        
        let videoNodeSizeInPoints = CGSize(width: videoSize.width / requiredScale, height: videoSize.height / requiredScale)
        videoNodeSize = videoNodeSizeInPoints.applying(.init(scaleX: requiredScale, y: requiredScale))
        
        let cameraNode = SKCameraNode()
        camera = cameraNode
        scene?.addChild(cameraNode)
        camera?.setScale(requiredScale)
        
        videoNode = SKVideoNode(url: videoURL)
        addChild(videoNode)
        videoNode.play()
        
        setupBackButton()
    }
    
    func setupBackButton() {
        backButton = SKSpriteNode(texture: .none, color: .clear, size: CGSize(width: 322, height: 300))
        
        let image = SKSpriteNode(texture: SKTexture(imageNamed: "WR_backButton"), size: backButton.size)
        image.zPosition = 2
        image.anchorPoint = CGPoint(x: 0, y: 1)
        
        let background = SKShapeNode(rect: CGRect(origin: CGPoint(x: 0, y: -backButton.size.height), size: backButton.size), cornerRadius: 24)
        background.fillColor = #colorLiteral(red: 0.1921389997, green: 0.1921669245, blue: 0.1921294034, alpha: 1)
        background.strokeColor = .clear
        background.zPosition = 1
        
        backButton.addChild(image)
        backButton.addChild(background)
        backButton.position = CGPoint(x: -videoNodeSize.width, y: videoNodeSize.height) * 0.45
        addChild(backButton)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchLocation = touch!.location(in: self)
        
        if backButton.contains(touchLocation) && backActive {
            endPlayback()
        }
        
        updateBackButton()
    }
    
    func updateBackButton() {
        if backActive {
            backActive.toggle()
            backButton.run(SKAction.fadeOut(withDuration: 0.5), withKey: "fadeOut")
        } else {
            backActive.toggle()
            backButton.removeAction(forKey: "fadeOut")
            backButton.alpha = 1
            backTime = 0
        }
    }
    
    func endPlayback() {
        playbackEnded = true
        videoNode.pause()
        coordinator?.popToRoot()
    }
    
    var lastUpdateTime: TimeInterval = 0
    var totalTime: Double = 0 //seconds
    var backTime: Double = 0 //seconds
    var playbackEnded = false
    
    override func update(_ currentTime: TimeInterval) {

        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        totalTime += Double(deltaTime)
        backTime += Double(deltaTime)
        
        if backTime >= 3 && backActive {
            updateBackButton()
        }
        
        if totalTime >= videoDuration && !playbackEnded {
            endPlayback()
        }
        
    }
}
