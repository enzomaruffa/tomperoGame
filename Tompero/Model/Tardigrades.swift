//
//  Tardigrades.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class Tardigrades: Ingredient {
    
    init(currentOwner: String) {
        super.init(
            name: "Tardigrades",
            texturePrefix: "",
            currentOwner: currentOwner,
            recipe: [.raw, .fried, .burnt]
        )
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
