//
//  Order.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class Order: HasIngredients, Codable {
    var ingredients: [Ingredient] = []
    var timeLeft: Int
    
    init(timeLeft: Int) {
        self.timeLeft = timeLeft
    }
    
    convenience init() {
        self.init(timeLeft: 30)
    }
}
