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
    var timeLeft: Float
    
    var score: Int {
        (8 + Int(ceil(timeLeft/10)) * 2)
    }
    
    init(timeLeft: Float) {
        self.timeLeft = timeLeft
    }
    
    convenience init() {
        self.init(timeLeft: 30)
    }
}
