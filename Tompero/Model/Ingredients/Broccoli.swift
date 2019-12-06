//
//  Broccoli.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class Broccoli: Ingredient {
    
    init() {
        super.init(
            texturePrefix: "Broccoli",
            actionCount: 2,
            finalState: .chopped
        )
        
        self.states = [
            .raw: [.chopping],
            .chopping: [.raw, .chopping, .chopped]
        ]
        
        self.choppableComponent = ChoppableComponent()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
