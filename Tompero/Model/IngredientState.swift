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
    
    case chopping = "Kinda chopped"
    case chopped = "Chopped"
    
    case cooking = "Kinda Cooked"
    case cooked = "Cooked"
    
    case frying = "Kinda Fried"
    case fried = "Fried"
    
    case burnt = "Burnt"
}
