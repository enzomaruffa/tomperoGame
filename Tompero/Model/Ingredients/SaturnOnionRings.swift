//
//  SaturnOnionRings.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class SaturnOnionRings: Ingredient {
    
    init(currentOwner: String) {
        super.init(
            texturePrefix: "",
            currentOwner: currentOwner,
            actionCount: 3,
            finalState: .raw
        )
        
        self.states = [
            .raw: [.chopping],
            .chopping: [.raw, .chopping, .chopped],
            .chopped: [.frying],
            .frying: [.chopped, .frying, .fried],
            .fried: [.burnt],
            .burnt: []
        ]
        
        self.components = [
            ChoppableComponent(),
            FryableComponent()
        ]
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
