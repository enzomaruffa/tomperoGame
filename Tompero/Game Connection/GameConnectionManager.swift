//
//  GameConnectionManager.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class GameConnectionManager: MCManagerDataObserver {

    var observers: [GameConnectionManagerObserver] = []
    
    static let shared = GameConnectionManager()
    
    private init() {
        MCManager.shared.subscribeDataObserver(observer: self)
    }
    
    func receiveData(wrapper: MCDataWrapper) {
        switch wrapper.type {
        case .plate:
            do {
//                let plate = try JSONDecoder().decode(Plate.self, from: wrapper.object)
//                receivePlate
//                observers.forEach({ $0.receivePlate(plate: plate) })
            } catch let error {
                print("[GameConnectionManager] Error decoding: \(error.localizedDescription)")
            }
            
            break
        default:
            print("[GameConnectionManager] Unknown type received")
        }
        // TODO: Decodificar o ingrediente em outrostipos
    }
//    
//    func sendIngredient(ingredient: Ingredient) {
//
//    }
    
}
