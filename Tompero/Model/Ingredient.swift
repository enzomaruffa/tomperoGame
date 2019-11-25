//
//  Ingredient.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class Ingredient: Transferable {
    var name: String
    var textureName: String
    var currentOwner: String
    
    init(name: String, textureName: String, currentOwner: String) {
        self.name = name
        self.textureName = textureName
        self.currentOwner = currentOwner
    }
}
