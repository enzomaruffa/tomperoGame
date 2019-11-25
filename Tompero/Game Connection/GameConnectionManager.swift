//
//  GameConnectionManager.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class GameConnectionManager: MCManagerDataObserver {
    
    static let shared = GameConnectionManager()
    
    private init() {
        MCManager.shared.subscribeDataObserver(observer: self)
    }
    
    func receiveData(wrapper: MCDataWrapper) {
        // TODO: Decodificar o ingrediente em outrostipos
    }
//    
//    func sendIngredient(ingredient: Ingredient) {
//
//    }
    
}
