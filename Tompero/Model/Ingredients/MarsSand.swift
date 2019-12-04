//
//  MarsSand.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class MarsSand: Ingredient {
    
    init(currentOwner: String) {
        super.init(
            texturePrefix: "MarsSand",
            currentOwner: currentOwner,
            actionCount: 2,
            finalState: .cooked
        )
        
        self.states = [
            .raw: [.cooking],
            .cooking: [.raw, .cooking, .cooked],
            .cooked: [.burnt],
            .burnt: []
        ]
        
        self.components = [
            CookableComponent()
        ]
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
