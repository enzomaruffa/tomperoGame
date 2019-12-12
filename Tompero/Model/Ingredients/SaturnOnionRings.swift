//
//  SaturnOnionRings.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class SaturnOnionRings: Ingredient {
    
    override var textureName: String {
        switch currentState {
        case .raw: return texturePrefix + "Raw"
        case .chopping: return texturePrefix + "Raw"
        case .chopped: return texturePrefix + "Chopped"
        case .cooking: return texturePrefix + "Raw"
        case .cooked: return texturePrefix + "Raw"
        case .frying: return texturePrefix + "Chopped"
        case .fried: return texturePrefix + "Fried"
        case .burnt: return "ashes"
        }
    }
    
    init() {
        super.init(
            texturePrefix: "SaturnOnionRings",
            actionCount: 3,
            finalState: .raw
        )
        
        self.states = [
            .raw: [.chopping],
            .chopping: [.raw, .chopping, .chopped],
            .chopped: [.frying],
            .frying: [.chopped, .frying, .fried],
            .fried: [.burnt],
            .burnt: []
        ]
        
        self.choppableComponent = ChoppableComponent()
        self.fryableComponent = FryableComponent()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override init(ingredient: Ingredient) {
        super.init(ingredient: ingredient)
    }
}
