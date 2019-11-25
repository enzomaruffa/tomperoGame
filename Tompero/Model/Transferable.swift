//
//  Transferable.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

protocol Transferable {
    var currentOwner: String { get set }
    
    func sendTo(_: String)
}

extension Transferable {
    func sendTo(_: String) {
        print("hello")
    }
}
