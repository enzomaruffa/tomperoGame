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
    
    var burnt: Bool {
        cookProgress >= burnCap
    }
    
    init(cookProgress: Float, cookIncrement: Float, cookCap: Float, burnCap: Float) {
        self.cookProgress = cookProgress
        self.cookIncrement = cookIncrement
        self.cookCap = cookCap
        self.burnCap = burnCap
        
        super.init()
        
        self.componentType = .cookable
    }
    
    convenience override init() {
        self.init(cookProgress: 0, cookIncrement: 20/60, cookCap: 100, burnCap: 200)
    }
    
    convenience init(cookProgress: Float, cookIncrement: Float) {
        self.init(cookProgress: cookProgress, cookIncrement: cookIncrement, cookCap: 100, burnCap: 200)
    }
    
    func update() {
        if !burnt {
            cookProgress += cookIncrement
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case cookProgress
        case cookIncrement
        case cookCap
        case burnCap
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cookProgress = try container.decode(Float.self, forKey: .cookProgress)
        self.cookIncrement = try container.decode(Float.self, forKey: .cookIncrement)
        self.cookCap = try container.decode(Float.self, forKey: .cookCap)
        self.burnCap = try container.decode(Float.self, forKey: .burnCap)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.cookProgress, forKey: .cookProgress)
        try container.encode(self.cookIncrement, forKey: .cookIncrement)
        try container.encode(self.cookCap, forKey: .cookCap)
        try container.encode(self.burnCap, forKey: .burnCap)
    }
}
