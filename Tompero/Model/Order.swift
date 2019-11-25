//
//  Order.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class Order: HasIngredients {
    var ingredients: [Ingredient]
    var timeLeft: Int
    
    init() {
        ingredients = [Ingredient]()
        timeLeft = 30
    }
}
