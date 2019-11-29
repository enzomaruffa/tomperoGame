//
//  StationNode.swift
//  Tompero
//
//  Created by Vinícius Binder on 29/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class StationNode {
    var station: PlayerTable
    
    var spriteNode: SKSpriteNode {
        station.type == .ingredient ? SKSpriteNode(imageNamed: NSStringFromClass(type(of: station.ingredient!)) + ".png") : SKSpriteNode(imageNamed: station.type.rawValue + ".png")
    }
    var spriteYPos: CGFloat {
        switch station.type {
        case .chopping: return -237.5
        case .cooking: return -348.5
        case .frying: return -342.0
        case .ingredient: return -200.0 // not final
        case .plate: return -200.0 // not final
        default: return 0.0
        }
    }
    
    internal init(station: PlayerTable) {
        self.station = station
    }
}
