//
//  SpaceshipHull.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class SpaceshipHull: Ingredient {
    
    init() {
        super.init(
            texturePrefix: "SpaceshipHull",
            actionCount: 1,
            finalState: .fried
        )
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override init(ingredient: Ingredient) {
        super.init(ingredient: ingredient)
    }
}
