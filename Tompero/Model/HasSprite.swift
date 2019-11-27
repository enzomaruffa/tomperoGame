//
//  HasSprite.swift
//  Tompero
//
//  Created by Vinícius Binder on 26/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

protocol HasSprite {
    
    var textureName: String { get }
    
}

extension HasSprite {
    
    var sprite: SKSpriteNode {
        SKSpriteNode(imageNamed: textureName)
    }
    
}

// Dúvidas:
//  Como lidar com o sprite (fazer um SpriteComponent tipo no GameplayKit?)
//  Como/por quem os componentes serão chamados/alterados?
//
// Falta:
//  Checagem pra ver se é ou não fritável (percorrer lista de componentes)
