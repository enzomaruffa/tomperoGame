//
//  Ingredient.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class Ingredient: HasSprite, Transferable, Equatable, Codable {
    
    var texturePrefix: String
    var textureName: String {
        switch currentState {
        case .raw: return texturePrefix + "Raw"
        case .chopping: return texturePrefix + "Raw"
        case .chopped: return texturePrefix + "Chopped"
        case .cooking: return texturePrefix + "Chopped"
        case .cooked: return texturePrefix + "Cooked"
        case .frying: return texturePrefix + "Chopped"
        case .fried: return texturePrefix + "Fried"
        case .burnt: return "ashes"
        }
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
    
    func attemptChangeState(to state: IngredientState) -> Bool {
        print("Attempting change from \(currentState) to \(state)")
        if states[currentState]!.contains(state) {
            currentState = state
            return true
        }
        return false
    }
    
}
