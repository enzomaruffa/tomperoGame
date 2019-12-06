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
        
        self.componentType = .choppable
    }
    
    convenience override init() {
        self.init(chopProgress: 0, chopIncrement: 10, chopCap: 100)
    }
    
    convenience init(chopProgress: Float, chopIncrement: Float) {
        self.init(chopProgress: chopProgress, chopIncrement: chopIncrement, chopCap: 100)
    }
    
    func update() {
        if !complete {
            chopProgress += chopIncrement
            print("\(chopProgress)")
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case chopProgress
        case chopIncrement
        case chopCap
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.chopProgress = try container.decode(Float.self, forKey: .chopProgress)
        self.chopIncrement = try container.decode(Float.self, forKey: .chopIncrement)
        self.chopCap = try container.decode(Float.self, forKey: .chopCap)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.chopProgress, forKey: .chopProgress)
        try container.encode(self.chopIncrement, forKey: .chopIncrement)
        try container.encode(self.chopCap, forKey: .chopCap)
    }
}
