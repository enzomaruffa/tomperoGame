//
//  MarsSand.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class MarsSand: Ingredient {
    
    init() {
        super.init(
            texturePrefix: "MarsSand",
            actionCount: 2,
            finalState: .cooked
        )
        
        self.states = [
            .raw: [.cooking],
            .cooking: [.raw, .cooking, .cooked],
            .cooked: [.burnt],
            .burnt: []
        ]
        
        self.cookableComponent = CookableComponent()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override init(ingredient: Ingredient) {
        super.init(ingredient: ingredient)
    }
}
