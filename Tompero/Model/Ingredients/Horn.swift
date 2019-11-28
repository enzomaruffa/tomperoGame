//
//  Horn.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class Horn: Ingredient {
    
    init(currentOwner: String) {
        super.init(
            texturePrefix: "",
            currentOwner: currentOwner,
            actionCount: 3,
            finalState: .cooked
        )
        
        self.states = [
            .raw: [.chopping],
            .chopping: [.raw, .chopped],
            .chopped: [.cooking],
            .cooking: [.chopped, .cooked],
            .cooked: [.burnt]
        ]
        
        self.components = [
            ChoppableComponent(),
            CookableComponent()
        ]
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
