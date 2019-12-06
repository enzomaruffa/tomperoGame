//
//  Ingredient.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class Ingredient: HasSprite, Equatable, Codable {
    
    var texturePrefix: String
    var textureName: String {
        switch currentState {
        case .raw: return texturePrefix + "Raw"
        case .chopping: return texturePrefix + "Raw"
        case .chopped: return texturePrefix + "Chopped"
        case .cooking: return texturePrefix + "Raw"
        case .cooked: return texturePrefix + "Cooked"
        case .frying: return texturePrefix + "Raw"
        case .fried: return texturePrefix + "Fried"
        case .burnt: return "ashes"
        }
    }
    
    var states: [IngredientState: [IngredientState]] = [:]
    var currentState: IngredientState = .raw
    var finalState: IngredientState
    var isReady: Bool {
        currentState == finalState
    }
    
    var numberOfActionsTilReady: Int
    
    init(texturePrefix: String, actionCount: Int, finalState: IngredientState) {
        self.texturePrefix = texturePrefix
        self.numberOfActionsTilReady = actionCount
        self.finalState = finalState
    }
    
     init(ingredient: Ingredient) {
        self.texturePrefix = ingredient.texturePrefix
        self.numberOfActionsTilReady = ingredient.numberOfActionsTilReady
        self.finalState = ingredient.finalState
        self.choppableComponent = ingredient.choppableComponent
        self.cookableComponent = ingredient.cookableComponent
        self.fryableComponent = ingredient.fryableComponent
    }
    
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        return type(of: lhs) == type(of: rhs)
    }
    
    var choppableComponent: ChoppableComponent?
    var cookableComponent: CookableComponent?
    var fryableComponent: FryableComponent?
    
    var components: [Component] {
        var list: [Component] = []
        if let choppableComponent = self.choppableComponent { list.append(choppableComponent) }
        if let cookableComponent = self.cookableComponent { list.append(cookableComponent) }
        if let fryableComponent = self.fryableComponent { list.append(fryableComponent) }
        return list
    }
    
    func attemptChangeState(to state: IngredientState) -> Bool {
        print("Attempting change from \(currentState) to \(state)")
        if (states[currentState] ?? []).contains(state) {
            currentState = state
            return true
        }
        return false
    }
    
    func findDowncast() -> Ingredient {
        
//        switch texturePrefix {
//        case "Asteroid": return Asteroid()
//        default: break
//        }
        
        if texturePrefix == "Asteroid" {
            return Asteroid(ingredient: self)
        }
        Asteroid()
        if texturePrefix == "Broccoli" {
            return Broccoli(ingredient: self)
        }
        
        if texturePrefix == "DevilMashedBread" {
            return DevilMashedBread(ingredient: self)
        }
        
        if texturePrefix == "Eyes" {
            return Eyes(ingredient: self)
        }
        
        if texturePrefix == "Horn" {
            return Horn(ingredient: self)
        }
        
        if texturePrefix == "MarsSand" {
            return MarsSand(ingredient: self)
        }
        
        if texturePrefix == "MoonCheese" {
            return MoonCheese(ingredient: self)
        }
        
        if texturePrefix == "SaturnOnionRings" {
            return SaturnOnionRings(ingredient: self)
        }
        
        if texturePrefix == "SpaceshipHull" {
            return SpaceshipHull(ingredient: self)
        }
        
        if texturePrefix == "Tardigrades" {
            return Tardigrades(ingredient: self)
        }
        
        if texturePrefix == "Tentacle" {
            return Tentacle(ingredient: self)
        }
        
        print("Impossible to downcast")
        return self
    }
}
