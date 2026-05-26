//
//  SettingsView.swift
//  Tompero
//
//  Four-tab settings panel. Layout matches Settings.storyboard:
//  red background, header (back), selector strip (4 SelectorButton-style
//  tabs at 118.5, 36.5, 673, 50), and a Settings_box content panel at
//  (104.5, 86.5, 687, 278.5).
//

import SwiftUI
import GameKit

enum SettingsTab: Int, CaseIterable, Identifiable {
    case settings = 0, gameCenter = 1, stats = 2, credits = 3
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .settings: return "Settings"
        case .gameCenter: return "Game Center"
        case .stats: return "Stats"
        case .credits: return "Credits"
        }
    }
}

struct ContributorProfile: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let url: String
    let domain: String
}

private let contributors: [ContributorProfile] = [
    ContributorProfile(name: "Flavio Akira Tsukamoto", role: "Developer", url: "https://www.linkedin.com/in/akiratsu/", domain: "LinkedIn"),
    ContributorProfile(name: "Enzo Maruffa Moreira", role: "Developer", url: "https://www.linkedin.com/in/enzomaruffa/", domain: "LinkedIn"),
    ContributorProfile(name: "Leonardo Palinkas", role: "Artist", url: "https://www.behance.net/palinkas3239", domain: "Behance"),
    ContributorProfile(name: "Vinícius Binder", role: "Developer", url: "https://www.linkedin.com/in/viniciusbinder/", domain: "LinkedIn"),
    ContributorProfile(name: "Diego Pontes", role: "Sound Design & Music", url: "https://www.linkedin.com/in/diego-pontes/", domain: "LinkedIn")
]

final class MusicSettingsViewModel: ObservableObject {
    @Published var soundOn: Bool {
        didSet { MusicPlayer.shared.soundOn = soundOn }
    }
    @Published var musicOn: Bool {
        didSet {
            MusicPlayer.shared.musicOn = musicOn
            if musicOn { MusicPlayer.shared.play(.menu) } else { MusicPlayer.shared.stopAll() }
        }
    }
    init() {
        self.soundOn = MusicPlayer.shared.soundOn
        self.musicOn = MusicPlayer.shared.musicOn
    }
}

struct SettingsView: View {
    var initialTab: SettingsTab = .settings
    @EnvironmentObject private var router: AppRouter
    @StateObject private var music = MusicSettingsViewModel()
    @State private var selectedTab: SettingsTab = .settings
    @State private var showGameCenter = false
    @State private var redirectPrompt: ContributorProfile?

    var body: some View {
        DesignCanvas { scale in
            // Header back button
            Button {
                EventLogger.shared.logButtonPress(buttonName: "settings-back")
                router.pop()
            } label: {
                Image("WR_backButton")
                    .resizable()
                    .scaledToFit()
            }
            .buttonStyle(.plain)
            .designed(x: 48, y: 16, w: 63.5, h: 59, scale: scale)

            // Selector strip (118.5, 36.5, 673, 50) — four tabs side by side
            HStack(spacing: 0) {
                ForEach(SettingsTab.allCases) { tab in
                    TabPill(
                        title: tab.title,
                        isSelected: selectedTab == tab,
                        scale: scale
                    ) {
                        selectedTab = tab
                    }
                }
            }
            .designed(x: 118.5, y: 36.5, w: 673, h: 50, scale: scale)

            // Box panel (104.5, 86.5, 687, 278.5)
            Image("Settings_box")
                .resizable()
                .scaledToFit()
                .designed(x: 104.5, y: 86.5, w: 687, h: 278.5, scale: scale)

            // Tab content panel — inset inside the box (17.5, 0, 669.5, 239.5)
            // relative to box (104.5, 86.5) → absolute (122, 86.5)
            tabContent(scale: scale)
                .designed(x: 122, y: 86.5, w: 669.5, h: 278.5, scale: scale)
        }
        .onAppear { selectedTab = initialTab }
        .sheet(isPresented: $showGameCenter) {
            GameCenterDashboard()
        }
        .alert(item: $redirectPrompt) { profile in
            Alert(
                title: Text(String(localized: "alert.redirect.title")),
                message: Text(String(format: String(localized: "alert.redirect.message"), profile.domain)),
                primaryButton: .default(Text(String(localized: "alert.redirect.confirm"))) {
                    if let url = URL(string: profile.url) {
                        UIApplication.shared.open(url)
                    }
                },
                secondaryButton: .cancel(Text(String(localized: "alert.cancel")))
            )
        }
    }

    @ViewBuilder
    private func tabContent(scale: CGFloat) -> some View {
        switch selectedTab {
        case .settings: settingsTab(scale: scale)
        case .gameCenter: gameCenterTab(scale: scale)
        case .stats: statsTab(scale: scale)
        case .credits: creditsTab(scale: scale)
        }
    }

    private func settingsTab(scale: CGFloat) -> some View {
        VStack(spacing: 16 * scale) {
            HStack(spacing: 24 * scale) {
                Text("Sound")
                    .font(.custom("TitilliumWeb-Bold", size: 22 * scale))
                    .foregroundColor(.white)
                Toggle("", isOn: $music.soundOn)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.66, green: 0.20, blue: 0.27)))
            }
            HStack(spacing: 24 * scale) {
                Text("Music")
                    .font(.custom("TitilliumWeb-Bold", size: 22 * scale))
                    .foregroundColor(.white)
                Toggle("", isOn: $music.musicOn)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.66, green: 0.20, blue: 0.27)))
            }
            Button {
                MusicPlayer.shared.stopAll()
                router.push(.video)
            } label: {
                Text("Play Cutscene")
                    .font(.custom("TitilliumWeb-Bold", size: 20 * scale))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24 * scale)
                    .padding(.vertical, 8 * scale)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(10 * scale)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func gameCenterTab(scale: CGFloat) -> some View {
        VStack {
            Spacer()
            Button {
                showGameCenter = true
            } label: {
                Text("Leaderboards")
                    .font(.custom("TitilliumWeb-Bold", size: 24 * scale))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32 * scale)
                    .padding(.vertical, 12 * scale)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(12 * scale)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func statsTab(scale: CGFloat) -> some View {
        StatsTabView(scale: scale)
    }

    private func creditsTab(scale: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(contributors.enumerated()), id: \.element.id) { idx, profile in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(profile.name)
                                .font(.custom("TitilliumWeb-Bold", size: 16 * scale))
                                .foregroundColor(.white)
                            Text(profile.role)
                                .font(.custom("TitilliumWeb-Light", size: 12 * scale))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                        Image("\(profile.domain)Logo")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24 * scale, height: 24 * scale)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 16 * scale)
                    .padding(.vertical, 8 * scale)
                    .background(idx % 2 == 0 ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                    .contentShape(Rectangle())
                    .onTapGesture { redirectPrompt = profile }
                }
            }
        }
    }
}

private struct StatsTabView: View {
    let scale: CGFloat

    @State private var matches: Int = 0
    @State private var ordersDelivered: Int = 0
    @State private var coins: Int = 0
    @State private var accuracy: String = "—"
    @State private var bestEasy: Int = 0
    @State private var bestMedium: Int = 0
    @State private var bestHard: Int = 0
    @State private var actions: PlayerAwardStats = .zero

    var body: some View {
        VStack(spacing: 16 * scale) {
            HStack(spacing: 12 * scale) {
                StatsTile(label: "Matches", value: "\(matches)", scale: scale)
                StatsTile(label: "Delivered", value: "\(ordersDelivered)", scale: scale)
                StatsTile(label: "Coins", value: "\(coins)", scale: scale)
                StatsTile(label: "Accuracy", value: accuracy, scale: scale)
            }
            HStack(spacing: 12 * scale) {
                StatsTile(label: "Best Easy", value: "\(bestEasy)", scale: scale)
                StatsTile(label: "Best Medium", value: "\(bestMedium)", scale: scale)
                StatsTile(label: "Best Hard", value: "\(bestHard)", scale: scale)
            }
            HStack(spacing: 12 * scale) {
                StatsTile(label: "Chops", value: "\(actions.chopActions)", scale: scale)
                StatsTile(label: "Cooks", value: "\(actions.cookActions)", scale: scale)
                StatsTile(label: "Fries", value: "\(actions.fryActions)", scale: scale)
                StatsTile(label: "Plates", value: "\(actions.platesCreated)", scale: scale)
                StatsTile(label: "Pipes", value: "\(actions.pipeForwards)", scale: scale)
            }
            Spacer()
        }
        .padding(.horizontal, 16 * scale)
        .padding(.top, 12 * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: loadStats)
    }

    private func loadStats() {
        let store = PlayerStatsStore.shared
        withAnimation(.easeOut(duration: 0.6)) {
            matches = store.totalMatches
            ordersDelivered = store.totalOrdersDelivered
            coins = store.totalCoinsEarned
            bestEasy = store.bestScore(for: .easy)
            bestMedium = store.bestScore(for: .medium)
            bestHard = store.bestScore(for: .hard)
            actions = store.lifetimeActions
        }
        if let acc = store.accuracy {
            accuracy = String(format: "%.0f%%", acc * 100)
        } else {
            accuracy = "—"
        }
    }
}

private struct StatsTile: View {
    let label: String
    let value: String
    let scale: CGFloat

    var body: some View {
        VStack(spacing: 4 * scale) {
            Text(value)
                .font(.custom("TitilliumWeb-Bold", size: 24 * scale))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
            Text(label)
                .font(.custom("TitilliumWeb-Light", size: 11 * scale))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10 * scale)
        .background(Color.white.opacity(0.12))
        .cornerRadius(8 * scale)
    }
}

private struct TabPill: View {
    let title: String
    let isSelected: Bool
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Image(isSelected ? "Settings_selectionButtonON" : "Settings_selectionButtonOFF")
                    .resizable()
                    .scaledToFit()
                Text(title)
                    .font(.custom(isSelected ? "TitilliumWeb-Bold" : "TitilliumWeb-Light",
                                  size: (isSelected ? 18 : 14) * scale))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
