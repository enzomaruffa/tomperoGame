//
//  Broccoli.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class Broccoli: Ingredient {
    
    init(currentOwner: String) {
        super.init(
            name: "Broccoli",
            texturePrefix: "",
            currentOwner: currentOwner,
            recipe: [.raw, .chopped]
        )
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
