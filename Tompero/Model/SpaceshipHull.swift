//
//  SpaceshipHull.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class SpaceshipHull: Ingredient {
    
    init(currentOwner: String) {
        super.init(
            name: "Spaceship Hull",
            texturePrefix: "",
            currentOwner: currentOwner,
            recipe: [.raw]
        )
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
