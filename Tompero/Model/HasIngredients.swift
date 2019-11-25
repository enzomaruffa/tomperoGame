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
    
    func isEqual(to other: HasIngredients) -> Bool {
        return self.ingredients.elementsEqual(other.ingredients)
    }
}
