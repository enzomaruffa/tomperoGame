//
//  ChoppableComponent.swift
//  Tompero
//
//  Created by Vinícius Binder on 26/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class ChoppableComponent: Component, Completable {
    
    var chopProgress: Float
    var chopIncrement: Float
    var chopCap: Float
    
    var complete: Bool {
        chopProgress >= chopCap
    }
    
    init(chopProgress: Float, chopIncrement: Float, chopCap: Float) {
        self.chopProgress = chopProgress
        self.chopIncrement = chopIncrement
        self.chopCap = chopCap
        
        super.init()
    }
    
    convenience override init() {
        self.init(chopProgress: 0, chopIncrement: 10, chopCap: 100)
    }
    
    convenience init(chopProgress: Float, chopIncrement: Float) {
        self.init(chopProgress: chopProgress, chopIncrement: chopIncrement, chopCap: 100)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func update() {
        if !complete {
            chopProgress += chopIncrement
        }
    }
}
