//
//  PeerWithStatus.swift
//  Tompero
//

import Foundation

/// Lobby slot describing a participant and their current connection state.
/// Wire-compatible replacement for `MCPeerWithStatus`.
final class PeerWithStatus: Codable, Equatable {

    var name: String
    var status: PeerConnectionState

    init(name: String, status: PeerConnectionState) {
        self.name = name
        self.status = status
    }

    static func == (lhs: PeerWithStatus, rhs: PeerWithStatus) -> Bool {
        lhs.name == rhs.name && lhs.status == rhs.status
    }

    func copy() -> PeerWithStatus {
        PeerWithStatus(name: name, status: status)
    }
}
