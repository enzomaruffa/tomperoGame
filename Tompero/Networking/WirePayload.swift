//
//  WirePayload.swift
//  Tompero
//
//  Application-level payload carried inside `LANEnvelope`. Modeled as an
//  enum so every send/receive site is exhaustively typed by the compiler.
//  The Codable layout intentionally matches the old struct shape
//  (`{ "object": <base64-json>, "type": <int> }`) so the wire format is
//  identical to pre-refactor binaries.
//

import Foundation

enum WirePayload {
    case ingredient(Ingredient)
    case plate(Plate)
    case string(String)
    case playerData([PeerWithStatus])
    case gameRule(GameRule)
    case orders([Order])
    case deliveryNotification(OrderDeliveryNotification)
    case statistics(MatchStatistics)
}

extension WirePayload: Codable {

    private enum CodingKeys: String, CodingKey {
        case object
        case type
    }

    /// Numeric discriminator — these raw values match the legacy
    /// `WirePayloadType` enum so the wire format is unchanged.
    private enum Discriminator: Int, Codable {
        case ingredient = 0
        case plate = 1
        case string = 2
        case playerData = 3
        case gameRule = 4
        case orders = 5
        case deliveryNotification = 6
        case statistics = 7
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .ingredient(let value):
            try container.encode(Discriminator.ingredient, forKey: .type)
            try container.encode(try JSONEncoder().encode(value), forKey: .object)
        case .plate(let value):
            try container.encode(Discriminator.plate, forKey: .type)
            try container.encode(try JSONEncoder().encode(value), forKey: .object)
        case .string(let value):
            try container.encode(Discriminator.string, forKey: .type)
            try container.encode(try JSONEncoder().encode(value), forKey: .object)
        case .playerData(let value):
            try container.encode(Discriminator.playerData, forKey: .type)
            try container.encode(try JSONEncoder().encode(value), forKey: .object)
        case .gameRule(let value):
            try container.encode(Discriminator.gameRule, forKey: .type)
            try container.encode(try JSONEncoder().encode(value), forKey: .object)
        case .orders(let value):
            try container.encode(Discriminator.orders, forKey: .type)
            try container.encode(try JSONEncoder().encode(value), forKey: .object)
        case .deliveryNotification(let value):
            try container.encode(Discriminator.deliveryNotification, forKey: .type)
            try container.encode(try JSONEncoder().encode(value), forKey: .object)
        case .statistics(let value):
            try container.encode(Discriminator.statistics, forKey: .type)
            try container.encode(try JSONEncoder().encode(value), forKey: .object)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let discriminator = try container.decode(Discriminator.self, forKey: .type)
        let inner = try container.decode(Data.self, forKey: .object)
        let json = JSONDecoder()

        switch discriminator {
        case .ingredient:
            // Ingredient is a class hierarchy that JSONDecoder can't auto-route;
            // findDowncast() is applied at the dispatch site.
            self = .ingredient(try json.decode(Ingredient.self, from: inner))
        case .plate:
            self = .plate(try json.decode(Plate.self, from: inner))
        case .string:
            self = .string(try json.decode(String.self, from: inner))
        case .playerData:
            self = .playerData(try json.decode([PeerWithStatus].self, from: inner))
        case .gameRule:
            self = .gameRule(try json.decode(GameRule.self, from: inner))
        case .orders:
            self = .orders(try json.decode([Order].self, from: inner))
        case .deliveryNotification:
            self = .deliveryNotification(try json.decode(OrderDeliveryNotification.self, from: inner))
        case .statistics:
            self = .statistics(try json.decode(MatchStatistics.self, from: inner))
        }
    }
}
