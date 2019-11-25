//
//  Choppable.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

protocol Choppable {
    var chopped: Bool { get set }
    var choppedProgress: Float { get set } // [0..1]
    
    func chop()
}

extension Choppable {
    func chop() {
        
    }
}
