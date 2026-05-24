//
//  WaitingRoomView.swift
//  Tompero
//
//  Multiplayer lobby. Layout matches WaitingRoom.storyboard:
//  - Header (44, 0, 808, 73): back button, title, recipe-menu accessory
//  - Difficulty panel (44, 135.5, 193.5, 278.5) — host only
//  - Go panel (515, 273.5, 337, 140.5) — host only
//  - 4 player slots row (125, 108, 646, 157.5)
//

import SwiftUI

private let emptyName = "__empty__"

final class WaitingRoomViewModel: ObservableObject, LANMatchmakingObserver {

    @Published var players: [PeerWithStatus]
    @Published var difficulty: GameDifficulty = .easy
    @Published var showPicker: Bool = false
    @Published var startedGame: GameRule?
    /// On the joiner side, the name of the host who just connected. Drives
    /// the accept/decline invitation prompt. Cleared once the user decides.
    @Published var pendingInvitationFrom: String?

    let hosting: Bool
    /// True once the joiner has accepted (or declined) the first invite, so
    /// reconnect events don't re-prompt.
    private var hasRespondedToInvite = false

    init(hosting: Bool) {
        self.hosting = hosting
        if hosting {
            self.players = [
                PeerWithStatus(name: LANConnectionManager.shared.selfName, status: .connected),
                PeerWithStatus(name: emptyName, status: .notConnected),
                PeerWithStatus(name: emptyName, status: .notConnected),
                PeerWithStatus(name: emptyName, status: .notConnected)
            ]
            LANConnectionManager.shared.startHosting()
        } else {
            self.players = (0..<4).map { _ in PeerWithStatus(name: emptyName, status: .notConnected) }
            LANConnectionManager.shared.startJoining()
        }
        LANConnectionManager.shared.subscribeMatchmakingObserver(observer: self)
    }

    deinit {
        LANConnectionManager.shared.unsubscribeMatchmakingObserver(observer: self)
    }

    var canStart: Bool {
        players.filter { $0.status == .connected }.count > 1
    }

    func cycleDifficulty() {
        switch difficulty {
        case .easy: difficulty = .medium
        case .medium: difficulty = .hard
        case .hard: difficulty = .easy
        }
    }

    func startMatch() {
        let peers = players.map { $0.name }
        let rule = GameRuleFactory.generateRule(difficulty: difficulty, players: peers)
        do {
            let ruleData = try JSONEncoder().encode(rule)
            LANConnectionManager.shared.sendEveryone(dataWrapper: WirePayload(object: ruleData, type: .gameRule))
        } catch {
            Log.network.error("Failed to encode GameRule: \(error.localizedDescription, privacy: .public)")
            return
        }
        MusicPlayer.shared.stop(.menu)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.startedGame = rule
        }
    }

    // MARK: - LANMatchmakingObserver

    func receiveGameRule(rule: GameRule) {
        LANConnectionManager.shared.stopAdvertising()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            MusicPlayer.shared.stop(.menu)
            self.startedGame = rule
        }
    }

    func playerListSent(playersWithStatus: [PeerWithStatus]) {
        guard !hosting else { return }
        DispatchQueue.main.async {
            self.players = playersWithStatus
        }
    }

    func playerUpdate(player: String, state: PeerConnectionState) {
        if hosting {
            DispatchQueue.main.async {
                var newList = self.players.map { $0.copy() }
                if let existing = newList.first(where: { $0.name == player }) {
                    existing.status = state
                } else if let emptySlot = newList.first(where: { $0.name == emptyName }) {
                    emptySlot.name = player
                    emptySlot.status = state
                } else if let dropped = newList.first(where: { $0.status == .notConnected }) {
                    dropped.name = player
                    dropped.status = state
                }
                LANConnectionManager.shared.sendPeersStatus(playersWithStatus: newList)
                self.players = newList
            }
        } else if state == .connected, !hasRespondedToInvite {
            // Joiner side: first peer to fully connect is the host who invited
            // us. Show the accept/decline prompt before the user is committed
            // to the match.
            hasRespondedToInvite = true
            DispatchQueue.main.async {
                self.pendingInvitationFrom = player
            }
        }
    }

    func acceptInvitation() {
        pendingInvitationFrom = nil
    }

    func declineInvitation() {
        if let host = pendingInvitationFrom {
            LANConnectionManager.shared.disconnect(displayName: host)
        }
        pendingInvitationFrom = nil
        // Allow re-prompting if a different host invites next
        hasRespondedToInvite = false
    }
}

struct WaitingRoomView: View {
    let hosting: Bool
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: WaitingRoomViewModel

    init(hosting: Bool) {
        self.hosting = hosting
        _viewModel = StateObject(wrappedValue: WaitingRoomViewModel(hosting: hosting))
    }

    var body: some View {
        DesignCanvas { scale in
            // Header — back button + title
            HeaderBar(
                title: hosting ? "HOSTING..." : "WAITING...",
                scale: scale,
                onBack: {
                    EventLogger.shared.logButtonPress(buttonName: "waiting-back")
                    router.pop()
                }
            )

            // Recipe-menu accessory in the header (host & joiner both have it)
            // Original frame inside header: (606, 0, 192, 79.5) → absolute (650, 0)
            Image("WR_menuUI")
                .resizable()
                .scaledToFit()
                .designed(x: 650, y: 0, w: 192, h: 79.5, scale: scale)

            Button {
                EventLogger.shared.logButtonPress(buttonName: "waiting-recipeMenu")
                router.push(.menu)
            } label: {
                Image("WR_menuButton")
                    .resizable()
                    .scaledToFit()
            }
            .buttonStyle(.plain)
            .designed(x: 676.5, y: 38, w: 96.5, h: 26.5, scale: scale)

            // Difficulty panel — host only
            if hosting {
                Image("WR_difficultyUI")
                    .resizable()
                    .scaledToFit()
                    .designed(x: 44, y: 135.5, w: 193.5, h: 278.5, scale: scale)

                Button {
                    EventLogger.shared.logButtonPress(buttonName: "waiting-difficulty")
                    viewModel.cycleDifficulty()
                } label: {
                    Text(difficultyTitle)
                        .font(.custom("TitilliumWeb-Bold", size: 22 * scale))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                // Original (77.5, 198.5, 112, 30) inside difficulty view (44, 135.5)
                .designed(x: 121.5, y: 334, w: 112, h: 30, scale: scale)
            }

            // GO panel — host only
            if hosting {
                Image("WR_goUI")
                    .resizable()
                    .scaledToFit()
                    .designed(x: 515, y: 273.5, w: 337, h: 140.5, scale: scale)

                Button {
                    EventLogger.shared.logButtonPress(buttonName: "waiting-play")
                    viewModel.startMatch()
                } label: {
                    Image("WR_goButton")
                        .resizable()
                        .scaledToFit()
                        .opacity(viewModel.canStart ? 1.0 : 0.5)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canStart)
                // Inside go view at (207.5, 24, 72, 72)
                .designed(x: 722.5, y: 297.5, w: 72, h: 72, scale: scale)
            }

            // Player slots row at (125, 108, 646, 157.5) — 4 slots × 154w + 10 gap
            ForEach(0..<4, id: \.self) { index in
                PlayerSlotView(
                    player: viewModel.players[index],
                    slotIndex: index,
                    hosting: hosting,
                    scale: scale,
                    onInvite: {
                        EventLogger.shared.logButtonPress(buttonName: "waiting-invite")
                        viewModel.showPicker = true
                    }
                )
                .designed(x: 125 + CGFloat(index) * 164, y: 108, w: 154, h: 157.5, scale: scale)
            }
        }
        .sheet(isPresented: $viewModel.showPicker) {
            PeerPickerView()
        }
        .onReceive(viewModel.$startedGame.compactMap { $0 }) { rule in
            router.push(.game(rule: rule, hosting: hosting))
        }
        .alert(
            "Invitation",
            isPresented: Binding(
                get: { viewModel.pendingInvitationFrom != nil },
                set: { if !$0 { viewModel.acceptInvitation() } }
            ),
            presenting: viewModel.pendingInvitationFrom
        ) { _ in
            Button("Accept") { viewModel.acceptInvitation() }
            Button("Decline", role: .cancel) {
                viewModel.declineInvitation()
                router.pop()
            }
        } message: { host in
            Text("\(host) invited you to play.")
        }
    }

    private var difficultyTitle: String {
        switch viewModel.difficulty {
        case .easy: return String(localized: "difficulty.easy")
        case .medium: return String(localized: "difficulty.medium")
        case .hard: return String(localized: "difficulty.hard")
        }
    }
}

private struct PlayerSlotView: View {
    let player: PeerWithStatus
    let slotIndex: Int
    let hosting: Bool
    let scale: CGFloat
    let onInvite: () -> Void

    private static let hatNames = ["VREX", "SW77", "MORGAN", "JERRY"]
    /// Matches `GameScene.playerColorPalette` so the lobby slot shows the
    /// same player color the in-game UI uses for stations / plates.
    private static let slotColors: [Color] = [
        Color(red: 0.18, green: 0.41, blue: 0.97), // Blue
        Color(red: 0.62, green: 0.32, blue: 0.85), // Purple
        Color(red: 0.27, green: 0.78, blue: 0.41), // Green
        Color(red: 0.97, green: 0.55, blue: 0.18)  // Orange
    ]

    private var hatPrefix: String {
        PlayerSlotView.hatNames[min(slotIndex, PlayerSlotView.hatNames.count - 1)]
    }

    private var hatImage: String {
        switch player.status {
        case .notConnected: return "\(hatPrefix) - Vazio"
        case .connecting: return "\(hatPrefix) - redline"
        case .connected: return "\(hatPrefix) - FULL"
        }
    }

    private var label: String {
        if player.name == emptyName { return "" }
        switch player.status {
        case .connecting: return "…"
        default: return player.name
        }
    }

    var body: some View {
        ZStack {
            // Hat image (154, 129) anchored top
            Image(hatImage)
                .resizable()
                .scaledToFit()
                .frame(width: 154 * scale, height: 129 * scale)
                .frame(maxHeight: .infinity, alignment: .top)

            // Player name label (10, 133.5, 134, 24)
            Text(label)
                .font(.custom("TitilliumWeb-Bold", size: 16 * scale))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: 134 * scale, height: 24 * scale)
                .position(x: 77 * scale, y: 145.5 * scale)

            // Color strip — matches the player color used in-game so the
            // lobby slot reads as "you'll be the blue player".
            RoundedRectangle(cornerRadius: 3 * scale)
                .fill(PlayerSlotView.slotColors[min(slotIndex, PlayerSlotView.slotColors.count - 1)])
                .frame(width: 60 * scale, height: 4 * scale)
                .position(x: 77 * scale, y: 156 * scale)
                .opacity(player.status == .connected ? 1.0 : 0.4)

            // Invite button on empty slots (host only)
            if hosting && player.status == .notConnected {
                Button("INVITE", action: onInvite)
                    .font(.custom("TitilliumWeb-Bold", size: 20 * scale))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12 * scale)
                    .padding(.vertical, 6 * scale)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(10 * scale)
                    .position(x: 77 * scale, y: 60 * scale)
            }
        }
    }
}
