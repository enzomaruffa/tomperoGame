//
//  DevilMashedBread.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class DevilMashedBread: Ingredient {
    
    init(currentOwner: String) {
        super.init(
            name: "Devil-Mashed Bread",
            texturePrefix: "",
            currentOwner: currentOwner,
            recipe: [.raw]
        )
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
