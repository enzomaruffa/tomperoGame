//
//  Ingredient.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class Ingredient: HasSprite, Transferable, Equatable, Codable {
    
    var texturePrefix: String
    var textureName: String {
        texturePrefix + currentState.rawValue
        // update sprite (how?)
    }
    var currentOwner: String
    
    var components: [Component] = []
    
    var states: [IngredientState: [IngredientState]] = [:]
    var currentState: IngredientState = .raw
    var finalState: IngredientState
    var isReady: Bool {
        currentState == finalState
    }
    
    var numberOfActionsTilReady: Int
    
    init(texturePrefix: String, currentOwner: String, actionCount: Int, finalState: IngredientState) {
        self.texturePrefix = texturePrefix
        self.currentOwner = currentOwner
        self.numberOfActionsTilReady = actionCount
        self.finalState = finalState
    }
    
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        return type(of: lhs) == type(of: rhs)
    }
    
    var choppableComponent: ChoppableComponent? {
        components.first(where: { $0 is ChoppableComponent }) as? ChoppableComponent ?? nil
    }
    
    var cookableComponent: CookableComponent? {
        components.first(where: { $0 is CookableComponent }) as? CookableComponent ?? nil
    }

    var fryableComponent: FryableComponent? {
        components.first(where: { $0 is FryableComponent }) as? FryableComponent ?? nil
    }
    
    func update() {
        
    }
    
}
