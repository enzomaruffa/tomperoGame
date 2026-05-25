//
//  LANEvents.swift
//  Tompero
//
//  Event enums emitted by the network layer's Combine publishers. These
//  replaced hand-rolled NSHashTable<AnyObject> observers + protocols. The
//  shape mirrors the old protocol methods so call-site migration was a
//  mechanical swap from protocol conformance to a `.sink` switch.
//

import Foundation

enum LANMatchmakingEvent {
    case playerUpdate(player: String, state: PeerConnectionState)
    case playerListSent(playersWithStatus: [PeerWithStatus])
    case gameRule(GameRule)
}

enum GameEvent {
    case plate(Plate)
    case ingredient(Ingredient)
    case orders([Order])
    case deliveryNotification(OrderDeliveryNotification)
    case statistics(MatchStatistics)
}
