//
//  MCDataTypes.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

enum MCDataType: Int, Codable {
    case ingredient = 0
    case plate
    case string
    case playerData
    case gameRule
    case orders
    case deliveryNotification
}
