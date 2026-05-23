//
//  PeerConnectionState.swift
//  Tompero
//

import Foundation

/// Connection state for a remote peer. Replaces `MCSessionState` from
/// MultipeerConnectivity so the rest of the app no longer depends on that
/// framework's types.
enum PeerConnectionState: Int, Codable {
    case notConnected = 0
    case connecting = 1
    case connected = 2
}
