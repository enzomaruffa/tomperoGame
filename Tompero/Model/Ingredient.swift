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
    var currentState: IngredientState = .raw {
        willSet(value) {
            if value == .burnt {
                SFXPlayer.shared.burn.play()
            }
        }
    }
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
        self.states = ingredient.states
        self.currentState = ingredient.currentState
        
        if let choppableComponent = ingredient.choppableComponent {
            self.choppableComponent = ChoppableComponent(
                chopProgress: choppableComponent.chopProgress,
                chopIncrement: choppableComponent.chopIncrement,
                chopCap: choppableComponent.chopCap)
        }
        
        if let cookableComponent = ingredient.cookableComponent {
            self.cookableComponent = CookableComponent(
                cookProgress: cookableComponent.cookProgress,
                cookIncrement: cookableComponent.cookIncrement,
                cookCap: cookableComponent.cookCap,
                burnCap: cookableComponent.burnCap)
        }
        
        if let fryableComponent = ingredient.fryableComponent {
            self.fryableComponent = FryableComponent(
                fryProgress: fryableComponent.fryProgress,
                fryIncrement: fryableComponent.fryIncrement,
                fryCap: fryableComponent.fryCap,
                burnCap: fryableComponent.burnCap)
        }
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
        switch texturePrefix {
        case "Asteroid": return Asteroid(ingredient: self)
        case "Broccoli": return Broccoli(ingredient: self)
        case "DevilMashedBread": return DevilMashedBread(ingredient: self)
        case "Eyes": return Eyes(ingredient: self)
        case "Horn": return Horn(ingredient: self)
        case "MarsSand": return MarsSand(ingredient: self)
        case "MoonCheese": return MoonCheese(ingredient: self)
        case "SaturnOnionRings": return SaturnOnionRings(ingredient: self)
        case "SpaceshipHull": return SpaceshipHull(ingredient: self)
        case "Tardigrades": return Tardigrades(ingredient: self)
        case "Tentacle": return Tentacle(ingredient: self)
        default:
            print("Impossible to downcast")
            return self
        }
    }
}
