//
//  WaitingRoomView.swift
//  Tompero
//
//  Multiplayer lobby. Hosts a 4-slot player roster, a peer-picker sheet,
//  difficulty cycler, and the GO button that broadcasts a fresh GameRule.
//

import SwiftUI

private let emptyName = "__empty__"

/// Bridges the matchmaking observer protocol into `@Published` state.
final class WaitingRoomViewModel: ObservableObject, LANMatchmakingObserver {

    @Published var players: [PeerWithStatus]
    @Published var difficulty: GameDifficulty = .easy
    @Published var showPicker: Bool = false
    @Published var startedGame: GameRule?

    let hosting: Bool

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
        // Joiner path: host broadcasts the rule; we transition into the game.
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
        guard hosting else { return }
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
        ZStack(alignment: .top) {
            StarsBackground().ignoresSafeArea()

            VStack(spacing: 24) {
                header
                playerRow
                if hosting {
                    controls
                }
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.showPicker) {
            PeerPickerView()
        }
        .onReceive(viewModel.$startedGame.compactMap { $0 }) { rule in
            router.push(.game(rule: rule, hosting: hosting))
        }
    }

    private var header: some View {
        HStack {
            Button { router.pop() } label: {
                Image(systemName: "chevron.left")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
            }
            Spacer()
            Text(hosting ? "HOSTING…" : "WAITING…")
                .font(.custom("TitilliumWeb-Bold", size: 28))
                .foregroundColor(.white)
            Spacer()
            Button { router.push(.menu) } label: {
                Image(systemName: "book.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
            }
        }
    }

    private var playerRow: some View {
        HStack(spacing: 16) {
            ForEach(Array(viewModel.players.enumerated()), id: \.offset) { index, player in
                PlayerSlotView(
                    player: player,
                    slotIndex: index,
                    hosting: hosting,
                    onInvite: {
                        EventLogger.shared.logButtonPress(buttonName: "waiting-invite")
                        viewModel.showPicker = true
                    }
                )
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 24) {
            Button { viewModel.cycleDifficulty() } label: {
                Text(difficultyTitle)
                    .font(.custom("TitilliumWeb-Bold", size: 24))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(12)
            }
            Button {
                EventLogger.shared.logButtonPress(buttonName: "waiting-play")
                viewModel.startMatch()
            } label: {
                Text("GO")
                    .font(.custom("TitilliumWeb-Bold", size: 32))
                    .foregroundColor(.white)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                    .background(viewModel.canStart ? Color.green : Color.gray)
                    .cornerRadius(16)
            }
            .disabled(!viewModel.canStart)
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
    let onInvite: () -> Void

    private static let hatNames = ["VREX", "SW77", "MORGAN", "JERRY"]

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
        VStack(spacing: 8) {
            Image(hatImage)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .id(hatImage)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: hatImage)
            Text(label)
                .font(.custom("TitilliumWeb-Bold", size: 18))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if hosting && player.status == .notConnected {
                Button("INVITE", action: onInvite)
                    .font(.custom("TitilliumWeb-Bold", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(8)
            }
        }
    }
}
