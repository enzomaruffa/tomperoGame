//
//  HasIngredients.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

protocol HasIngredients {
    
    var ingredients: [Ingredient] { get set }
    
}

extension HasIngredients {
    
    func isEquivalent(to other: HasIngredients) -> Bool {
        return self.ingredients.sorted(by: {$0.texturePrefix < $1.texturePrefix}).elementsEqual(other.ingredients.sorted(by: {$0.texturePrefix < $1.texturePrefix}))
    }
    
}
