//
//  FryableComponent.swift
//  Tompero
//
//  Created by Vinícius Binder on 26/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class FryableComponent: Component, Completable {
    
    var fryProgress: Float
    var fryIncrement: Float
    var fryCap: Float
    var burnCap: Float
    
    var complete: Bool {
        fryProgress >= fryCap
    }
    
    init(fryProgress: Float, fryIncrement: Float, fryCap: Float, burnCap: Float) {
        self.fryProgress = fryProgress
        self.fryIncrement = fryIncrement
        self.fryCap = fryCap
        self.burnCap = burnCap
        
        super.init()
    }
    
    convenience override init() {
        self.init(fryProgress: 0, fryIncrement: 10, fryCap: 100, burnCap: 200)
    }
    
    convenience init(fryProgress: Float, fryIncrement: Float) {
        self.init(fryProgress: fryProgress, fryIncrement: fryIncrement, fryCap: 100, burnCap: 200)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func update() {
        
    }
}
