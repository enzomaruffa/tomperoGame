//
//  IngredientState.swift
//  Tompero
//
//  Created by Vinícius Binder on 26/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

enum IngredientState: Int, Codable {
    case raw = 0
    
    case chopping
    case chopped
    
    case cooking
    case cooked
    
    case frying
    case fried
    
    case burnt
}
