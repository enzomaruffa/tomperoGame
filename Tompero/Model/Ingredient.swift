//
//  Ingredient.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

enum IngredientState: String, Codable {
    case raw = "Raw"
    case cooked = "Cooked"
    case fried = "Fried"
    case chopped = "Chopped"
    case burnt = "Burnt"
}

class Ingredient: Transferable, Equatable, Codable {
    var name: String
    var texturePrefix: String
    var textureName: String
    var currentOwner: String
    
    var recipe: [IngredientState]
    var currentStateIndex: Int = 0 {
        didSet {
            actionProgress = 0
            updateTexture()
        }
    }
    var actionProgress = 0
    
    let clicksToChop = 10
    let secondsToFry = 10
    let secondsToCook = 10
    let secondsToBurnInFryer = 10
    let secondsToBurnInPan = 10
    
    init(name: String, texturePrefix: String, currentOwner: String, recipe: [IngredientState]) {
        self.name = name
        self.currentOwner = currentOwner
        self.recipe = recipe
        self.texturePrefix = texturePrefix
        self.textureName = texturePrefix + IngredientState.raw.rawValue
    }
    
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        return lhs.name == rhs.name
    }
    
    func updateTexture() {
        textureName = texturePrefix + recipe[currentStateIndex].rawValue
        // update sprite
    }
    
    func chop() { // call every click on
        if recipe[currentStateIndex+1] == .chopped {
            if actionProgress < clicksToChop {
                actionProgress += 1
            } else {
                currentStateIndex += 1
            }
        }
    }
    
    func fry() { // call every second in fryer
        if recipe[currentStateIndex+1] == .fried {
            if actionProgress < secondsToFry {
                actionProgress += 1
            } else {
                currentStateIndex += 1
            }
        } else if recipe[currentStateIndex+1] == .burnt {
            if actionProgress < secondsToFry {
                actionProgress += 1
            } else {
                currentStateIndex += 1
            }
        }
    }
    
    func cook() { // call every second in pan
        if recipe[currentStateIndex+1] == .cooked {
            if actionProgress < secondsToCook {
                actionProgress += 1
            } else {
                currentStateIndex += 1
            }
        } else if recipe[currentStateIndex+1] == .burnt {
            if actionProgress < secondsToBurnInPan {
                actionProgress += 1
            } else {
                currentStateIndex += 1
            }
        }
    }
}
