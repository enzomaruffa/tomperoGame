//
//  WirePayloadType.swift
//  Tompero
//
//  Discriminator for `WirePayload.object`. Raw values are stable so existing
//  saved/in-flight messages decode correctly.
//

import Foundation

enum WirePayloadType: Int, Codable {
    case ingredient = 0
    case plate = 1
    case string = 2
    case playerData = 3
    case gameRule = 4
    case orders = 5
    case deliveryNotification = 6
    case statistics = 7
}
