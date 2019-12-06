//
//  Component.swift
//  Tompero
//
//  Created by Vinícius Binder on 26/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class Component: Codable {
    var componentType: ComponentType?
}

protocol Completable {
    var complete: Bool { get }
    func update()
}
