//
//  PeerIdentity.swift
//  Tompero
//

import Foundation
import UIKit

/// Stable per-install identity for a participant. The `displayName` is what
/// shows up in the lobby and is used as the routing key for direct sends;
/// `id` is the stable UUID that survives display-name changes.
struct PeerIdentity: Codable, Hashable {
    let id: UUID
    let displayName: String
}

/// Loads (or, on first launch, generates) this device's persistent identity.
/// Keeping the UUID stable across launches matters once we reconnect: peers
/// recognize each other by `id`, not by display name.
enum LocalPeerIdentity {

    private static let idKey = "com.spacespice.lanPeer.id"
    private static let displayNameKey = "com.spacespice.lanPeer.displayName"
    private static let suffixKey = "com.spacespice.lanPeer.suffix"

    static var current: PeerIdentity = {
        let defaults = UserDefaults.standard

        let id: UUID
        if let raw = defaults.string(forKey: idKey), let saved = UUID(uuidString: raw) {
            id = saved
        } else {
            id = UUID()
            defaults.set(id.uuidString, forKey: idKey)
        }

        let displayName = makeStableDisplayName()
        defaults.set(displayName, forKey: displayNameKey)
        return PeerIdentity(id: id, displayName: displayName)
    }()

    // Bonjour-discovered names need to be unique on the LAN. iOS 16 returns
    // a generic model name from UIDevice.current.name without the
    // user-assigned-device-name entitlement, so we tag a stable random suffix
    // generated once per install.
    private static func makeStableDisplayName() -> String {
        let defaults = UserDefaults.standard
        let base = sanitize(UIDevice.current.name)

        let suffix: String
        if let existing = defaults.string(forKey: suffixKey) {
            suffix = existing
        } else {
            suffix = String(UUID().uuidString.prefix(4))
            defaults.set(suffix, forKey: suffixKey)
        }

        let suffixWrapped = " (\(suffix))"
        let maxBaseBytes = 63 - suffixWrapped.utf8.count
        let truncatedBase = truncate(base, toUTF8Bytes: maxBaseBytes)
        return truncatedBase + suffixWrapped
    }

    private static func sanitize(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Player" : trimmed
    }

    private static func truncate(_ string: String, toUTF8Bytes max: Int) -> String {
        guard max > 0 else { return "" }
        var result = string
        while result.utf8.count > max {
            result.removeLast()
        }
        return result
    }
}
