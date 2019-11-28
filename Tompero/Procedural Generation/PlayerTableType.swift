//
//  PlayerTableType.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 27/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

enum PlayerTableType: Int, Codable {
    case chopping = 0
    case cooking
    case frying
    case ingredient
    case plate
    case empty
}
