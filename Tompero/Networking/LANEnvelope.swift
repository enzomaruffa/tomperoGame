//
//  LANEnvelope.swift
//  Tompero
//

import Foundation

/// On-wire envelope wrapping every cross-peer payload. The host is a relay,
/// so envelopes carry both the original sender and (optionally) a single
/// targeted recipient so the host can route direct sends without re-encoding.
struct LANEnvelope: Codable {
    /// Display name of the original sender (matches `PeerIdentity.displayName`).
    let from: String
    /// Recipient display name, or nil for broadcast to all connected peers.
    let to: String?
    /// The application-level payload (same type the rest of the app already
    /// uses — keeps `MCDataWrapper`'s on-the-wire format untouched so this
    /// swap is transport-only).
    let payload: MCDataWrapper
}

/// Bootstrap message exchanged immediately after a TCP connection is
/// established. Tells the other side who we are so the manager can wire the
/// connection into its peer table keyed by displayName.
struct LANHandshake: Codable {
    let peer: PeerIdentity
    let isHost: Bool
}

/// Heartbeat frame so each side can prove liveness independently of the TCP
/// stack — `NWConnection` doesn't notice a wedged peer for ~60s, our app
/// gives up after 6.
struct LANPing: Codable {
    let id: UUID
}

struct LANPong: Codable {
    let id: UUID
}

/// Tagged frame the wire carries. Either one of two control messages
/// (handshake, ping/pong) or an application-level envelope.
enum LANFrame: Codable {
    case handshake(LANHandshake)
    case envelope(LANEnvelope)
    case ping(LANPing)
    case pong(LANPong)
}
