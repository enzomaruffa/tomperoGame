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
    private static let userSetNameKey = "com.spacespice.lanPeer.userSetName"

    /// The user's chosen display name (without the disambiguation suffix), or
    /// nil if they've never set one. UI surfaces this in the editor; the
    /// computed identity below always adds a suffix on top so peers on the
    /// LAN don't collide.
    static var userSetName: String? {
        get { UserDefaults.standard.string(forKey: userSetNameKey) }
    }

    /// Persist a new display name. Pass nil or empty to clear back to the
    /// device-name default. Callers should follow this with
    /// `LANConnectionManager.shared.resetSession()` so the listener restarts
    /// advertising the new name.
    @discardableResult
    static func setUserSetName(_ name: String?) -> PeerIdentity {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            UserDefaults.standard.set(trimmed, forKey: userSetNameKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userSetNameKey)
        }
        _current = makeIdentity()
        return _current
    }

    static var current: PeerIdentity { _current }
    private static var _current: PeerIdentity = makeIdentity()

    private static func makeIdentity() -> PeerIdentity {
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
    }

    // The visible name is `<base> (<XXXX>)` where:
    // - `<base>` is the user-chosen name, or `UIDevice.current.name` if none.
    //   iOS 16 returns a generic model name without the
    //   user-assigned-device-name entitlement, which is why a suffix is still
    //   needed.
    // - `<XXXX>` is a 4-character UUID-prefix tag generated once per install
    //   and stashed in UserDefaults, guaranteeing distinct routing keys even
    //   when two players choose the same human name.
    private static func makeStableDisplayName() -> String {
        let defaults = UserDefaults.standard
        let base = sanitize(userSetName ?? UIDevice.current.name)

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
