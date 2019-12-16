//
//  PlateBoxNode.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 16/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class PlateBoxNode: StationNode {
    
    override var spriteYPos: CGFloat {
        -361
    }
    
    init() {
        super.init(stationType: .plateBox, spriteNode: nil, ingredient: nil)
    }
    
    override func tap() {
        if self.plateNode == nil {
            let newPlate = Plate()
            let plateMovableNode = MovableSpriteNode(imageNamed: newPlate.textureName)
            spriteNode.scene!.addChild(plateMovableNode)
            plateMovableNode.zPosition = 4
            
            let plateNode = PlateNode(plate: newPlate, movableNode: plateMovableNode, currentLocation: self)
            plateMovableNode.position = CGPoint(x: spriteNode.position.x, y: spriteNode.position.y + 85)
            
            self.plateNode = plateNode
        }
    }
    
}
