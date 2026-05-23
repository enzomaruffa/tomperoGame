//
//  WirePayload.swift
//  Tompero
//
//  Application-level payload carried inside `LANEnvelope`. Pure Codable —
//  not bound to any transport — so we can swap the wire/encoder freely.
//

import Foundation

final class WirePayload: Codable {

    let object: Data
    let type: WirePayloadType

    init(object: Data, type: WirePayloadType) {
        self.object = object
        self.type = type
    }
}
