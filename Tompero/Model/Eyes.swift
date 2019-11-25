//
//  Eyes.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class Eyes: Ingredient {
    
    init(currentOwner: String) {
        super.init(
            name: "Eyes",
            texturePrefix: "",
            currentOwner: currentOwner,
            recipe: [.raw, .chopped]
        )
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
