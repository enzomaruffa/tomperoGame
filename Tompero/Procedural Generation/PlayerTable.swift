//
//  PlayerTable.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 27/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class PlayerTable {
    
    var type: PlayerTableType
    var ingredient: Ingredient.Type?
    
    var spriteImageName: String {
        type == .ingredient ?
            NSStringFromClass(ingredient!) + ".png"
            :
            type.rawValue + ".png"
    }
    var spriteYPos: CGFloat {
        switch type {
        case .chopping: return -237.5
        case .cooking: return -348.5
        case .frying: return -342.0
        case .ingredient: return -200.0 // not final
        case .plate: return -200.0 // not final
        default: return 0.0
        }
    }
    var secondarySpritesImageNames: [String] {
        if type == .cooking {
            return [] // burner, pan
        } else {
            return []
        }
    }
    
    internal init(type: PlayerTableType, ingredient: Ingredient.Type?) {
        self.type = type
        self.ingredient = ingredient
    }
    
    convenience init() {
        self.init(type: .empty, ingredient: nil)
    }
}
