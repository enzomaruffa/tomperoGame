//
//  PlayerTable.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 27/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class PlayerTable {
    
    var type: PlayerTableType
    var ingredient: Ingredient.Type?
    
    internal init(type: PlayerTableType, ingredient: Ingredient.Type?) {
        self.type = type
        self.ingredient = ingredient
    }
    
    convenience init() {
        self.init(type: .empty, ingredient: nil)
    }
}
