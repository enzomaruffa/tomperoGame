//
//  Asteroid.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class Asteroid: Ingredient {
    
    init(currentOwner: String) {
        super.init(
            texturePrefix: "Asteroid",
            currentOwner: currentOwner,
            actionCount: 1,
            finalState: .raw
        )
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
