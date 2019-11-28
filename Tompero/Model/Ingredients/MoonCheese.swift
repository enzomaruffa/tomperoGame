//
//  MoonCheese.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class MoonCheese: Ingredient {
    
    init(currentOwner: String) {
        super.init(
            texturePrefix: "",
            currentOwner: currentOwner,
            actionCount: 2,
            finalState: .chopped
        )
        
        self.states = [
            .raw: [.chopping],
            .chopping: [.raw, .chopped]
        ]
        
        self.components = [
            ChoppableComponent()
        ]
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
