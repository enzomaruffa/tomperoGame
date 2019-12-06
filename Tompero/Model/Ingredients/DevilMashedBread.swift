//
//  DevilMashedBread.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class DevilMashedBread: Ingredient {
    
    init() {
        super.init(
            texturePrefix: "DevilMashedBread",
            actionCount: 1,
            finalState: .raw
        )
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override init(ingredient: Ingredient) {
        super.init(ingredient: ingredient)
    }
}
