//
//  Tentacle.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class Tentacle: Ingredient {
    
    init() {
        super.init(
            texturePrefix: "Tentacle",
            actionCount: 3,
            finalState: .cooked
        )
        
        self.states = [
            .raw: [.chopping],
            .chopping: [.raw, .chopping, .chopped],
            .chopped: [.cooking],
            .cooking: [.chopped, .cooking, .cooked],
            .cooked: [.burnt],
            .burnt: []
        ]
        
        self.choppableComponent = ChoppableComponent()
        self.cookableComponent = CookableComponent()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
