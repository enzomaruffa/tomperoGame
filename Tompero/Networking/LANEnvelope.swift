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

/// First-frame discriminator so a connection can carry either a handshake
/// (once at connect time) or a stream of envelopes (everything after). Tagged
/// JSON keeps the framing dead simple — no separate channel.
enum LANFrame: Codable {
    case handshake(LANHandshake)
    case envelope(LANEnvelope)
}
