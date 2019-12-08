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
    
    var burnt: Bool {
        fryProgress >= burnCap
    }
    
    init(fryProgress: Float, fryIncrement: Float, fryCap: Float, burnCap: Float) {
        self.fryProgress = fryProgress
        self.fryIncrement = fryIncrement
        self.fryCap = fryCap
        self.burnCap = burnCap
        
        super.init()
        
        self.componentType = .fryable
    }
    
    convenience override init() {
        self.init(fryProgress: 0, fryIncrement: 20/60, fryCap: 100, burnCap: 200)
    }
    
    convenience init(fryProgress: Float, fryIncrement: Float) {
        self.init(fryProgress: fryProgress, fryIncrement: fryIncrement, fryCap: 100, burnCap: 200)
    }
    
    func update() {
        if !complete {
            fryProgress += fryIncrement
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case fryProgress
        case fryIncrement
        case fryCap
        case burnCap
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.fryProgress = try container.decode(Float.self, forKey: .fryProgress)
        self.fryIncrement = try container.decode(Float.self, forKey: .fryIncrement)
        self.fryCap = try container.decode(Float.self, forKey: .fryCap)
        self.burnCap = try container.decode(Float.self, forKey: .burnCap)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.fryProgress, forKey: .fryProgress)
        try container.encode(self.fryIncrement, forKey: .fryIncrement)
        try container.encode(self.fryCap, forKey: .fryCap)
        try container.encode(self.burnCap, forKey: .burnCap)
    }
}
