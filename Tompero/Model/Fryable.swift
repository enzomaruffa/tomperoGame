//
//  Fryable.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

protocol Fryable {
    var fried: Bool { get set }
    var friedProgress: Float { get set } // [0..1]
    
    
}
