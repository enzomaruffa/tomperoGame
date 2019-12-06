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
    
    var components: [Component] = []
    
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
            return Asteroid()
        }
        
        if texturePrefix == "Broccoli" {
            return Broccoli()
        }
        
        if texturePrefix == "DevilMashedBread" {
            return DevilMashedBread()
        }
        
        if texturePrefix == "Eyes" {
            return Eyes()
        }
        
        if texturePrefix == "Horn" {
            return Horn()
        }
        
        if texturePrefix == "MarsSand" {
            return MarsSand()
        }
        
        if texturePrefix == "MoonCheese" {
            return MoonCheese()
        }
        
        if texturePrefix == "SaturnOnionRings" {
            return SaturnOnionRings()
        }
        
        if texturePrefix == "SpaceshipHull" {
            return SpaceshipHull()
        }
        
        if texturePrefix == "Tardigrades" {
            return Tardigrades()
        }
        
        if texturePrefix == "Tentacle" {
            return Tentacle()
        }
        
        print("Impossible to downcast")
        return self
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        texturePrefix = try values.decode(String.self, forKey: .texturePrefix)
        states = try values.decode([IngredientState: [IngredientState]].self, forKey: .states)
        currentState = try values.decode(IngredientState.self, forKey: .currentState)
        finalState = try values.decode(IngredientState.self, forKey: .finalState)
        numberOfActionsTilReady = try values.decode(Int.self, forKey: .numberOfActionsTilReady)

        let components = try values.decode([Component].self, forKey: .components)

        components.forEach({ print($0.componentType, type(of: $0)) })
        
//        for component in components {
//            switch component.componentType {
//            case .choppable:
//                self.components.append(try ChoppableComponent(from: decoder))
//            case .cookable:
//                self.components.append(try CookableComponent(from: decoder))
//            case .fryable:
//                self.components.append(try FryableComponent(from: decoder))
//            case .none: break
//            }
//        }
    }
    
}
