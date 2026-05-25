//
//  MatchContext.swift
//  Tompero
//
//  Immutable per-match info derived from the GameRule + local identity.
//  Replaces the scattered computed properties on GameScene that recomputed
//  the same answers (player color, peer order, peer colors, this player's
//  tables) every read.
//

import Foundation

struct MatchContext {
    /// The procedurally-generated rule that drives the entire match. Held
    /// for downstream reads (`generateOrder()`, `difficulty`, etc.).
    let rule: GameRule

    /// True on the device acting as host. Drives the order generation loop
    /// and the host-only `endMatch` broadcast.
    let hosting: Bool

    /// Local player's display name — matches PeerIdentity.displayName.
    let player: String

    /// Full player list as the host pinned it, including `__empty__` slots.
    let playerOrder: [String]

    /// Player names other than `self`, in the same order pipes use.
    let otherPlayers: [String]

    /// Local player's color string ("Blue" / "Purple" / "Green" / "Orange").
    let playerColor: String

    /// Colors for the other players, in pipe order.
    let peerColors: [String]

    /// Table slots this device owns. Stays empty for `__empty__` players.
    let tables: [PlayerTable]

    private static let palette = ["Blue", "Purple", "Green", "Orange"]

    init(rule: GameRule, hosting: Bool, player: String) {
        self.rule = rule
        self.hosting = hosting
        self.player = player
        self.playerOrder = rule.playerOrder

        let myIndex = rule.playerOrder.firstIndex(of: player) ?? 0
        self.playerColor = MatchContext.palette[min(myIndex, MatchContext.palette.count - 1)]

        // Other players + peer colors are aligned by index so pipe1/pipe2/pipe3
        // routing keeps working without an explicit name→color map.
        var peers: [String] = []
        var peerPalette = MatchContext.palette
        peerPalette.remove(at: min(myIndex, peerPalette.count - 1))
        for name in rule.playerOrder where name != player {
            peers.append(name)
        }
        self.otherPlayers = peers
        self.peerColors = peerPalette

        self.tables = rule.playerTables[player] ?? []
    }
}
