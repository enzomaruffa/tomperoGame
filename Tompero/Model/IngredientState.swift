//
//  IngredientState.swift
//  Tompero
//
//  Created by Vinícius Binder on 26/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

enum IngredientState: String, Codable {
    case raw = "Raw"
    
    static var chopping: IngredientState { raw }
    case chopped = "Chopped"
    
    static var cooking: IngredientState { chopped }
    case cooked = "Cooked"
    
    static var frying: IngredientState { chopped }
    case fried = "Fried"
    
    case burnt = "Burnt"
}
