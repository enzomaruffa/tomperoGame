//
//  Plate.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class Plate: HasIngredients, Transferable, Codable {
    
    var ingredients: [Ingredient] = []
    var currentOwner: String
    
    init(currentOwner: String) {
        self.currentOwner = currentOwner
    }
}
