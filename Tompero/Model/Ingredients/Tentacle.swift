//
//  Tentacle.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class Tentacle: Ingredient {
    
    override var textureName: String {
        switch currentState {
        case .raw: return texturePrefix + "Raw"
        case .chopping: return texturePrefix + "Raw"
        case .chopped: return texturePrefix + "Chopped"
        case .cooking: return texturePrefix + "Chopped"
        case .cooked: return texturePrefix + "Cooked"
        case .frying: return texturePrefix + "Raw"
        case .fried: return texturePrefix + "Raw"
        case .burnt: return "ashes"
        }
    }
    
    init() {
        super.init(
            texturePrefix: "Tentacle",
            actionCount: 3,
            finalState: .cooked
        )
        
        self.states = [
            .raw: [.chopping],
            .chopping: [.raw, .chopping, .chopped],
            .chopped: [.cooking],
            .cooking: [.chopped, .cooking, .cooked],
            .cooked: [.burnt],
            .burnt: []
        ]
        
        self.choppableComponent = ChoppableComponent()
        self.cookableComponent = CookableComponent()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override init(ingredient: Ingredient) {
        super.init(ingredient: ingredient)
    }
}
