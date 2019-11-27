//
//  CookableComponent.swift
//  Tompero
//
//  Created by Vinícius Binder on 26/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class CookableComponent: Component, Completable {
    
    var cookProgress: Float
    var cookIncrement: Float
    var cookCap: Float
    var burnCap: Float
    
    var complete: Bool {
        cookProgress >= cookCap
    }
    
    init(cookProgress: Float, cookIncrement: Float, cookCap: Float, burnCap: Float) {
        self.cookProgress = cookProgress
        self.cookIncrement = cookIncrement
        self.cookCap = cookCap
        self.burnCap = burnCap
        
        super.init()
    }
    
    convenience override init() {
        self.init(cookProgress: 0, cookIncrement: 10, cookCap: 100, burnCap: 200)
    }
    
    convenience init(cookProgress: Float, cookIncrement: Float) {
        self.init(cookProgress: cookProgress, cookIncrement: cookIncrement, cookCap: 100, burnCap: 200)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func update() {
        
    }
}
