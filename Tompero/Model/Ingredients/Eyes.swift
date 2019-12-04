//
//  Eyes.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class Eyes: Ingredient {
    
    init() {
        super.init(
            texturePrefix: "Eyes",
            actionCount: 2,
            finalState: .fried
        )
        
        self.states = [
            .raw: [.frying],
            .frying: [.raw, .frying, .fried],
            .fried: [.burnt],
            .burnt: []
        ]
        
        self.components = [
            FryableComponent()
        ]
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
