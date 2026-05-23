//
//  SettingsView.swift
//  Tompero
//
//  Four-tab settings screen: Settings (sound / music toggles + cutscene),
//  Game Center (leaderboards), Stats ("Coming soon!"), Credits (contributor
//  list).
//

import SwiftUI
import GameKit

/// Tab identity; numeric raw values match the legacy tag-based selection
/// in the UIKit `SettingsViewController` for consistency.
enum SettingsTab: Int, CaseIterable, Identifiable {
    case settings = 0
    case gameCenter = 1
    case stats = 2
    case credits = 3

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

/// Bridges `MusicPlayer.shared`'s mutable toggles into `@Published`
/// properties SwiftUI can bind to.
final class MusicSettingsViewModel: ObservableObject {
    @Published var soundOn: Bool {
        didSet { MusicPlayer.shared.soundOn = soundOn }
    }
    @Published var musicOn: Bool {
        didSet {
            MusicPlayer.shared.musicOn = musicOn
            if musicOn {
                MusicPlayer.shared.play(.menu)
            } else {
                MusicPlayer.shared.stopAll()
            }
        }
    }

    init() {
        self.soundOn = MusicPlayer.shared.soundOn
        self.musicOn = MusicPlayer.shared.musicOn
    }
}

struct SettingsView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var music = MusicSettingsViewModel()

    @State private var selectedTab: SettingsTab = .settings
    @State private var showGameCenter = false
    @State private var redirectPrompt: ContributorProfile?

    var body: some View {
        ZStack(alignment: .topLeading) {
            StarsBackground().ignoresSafeArea()

            VStack(spacing: 16) {
                tabBar
                content
                Spacer()
            }
            .padding()

            Button {
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
            }
            .padding(.leading, 16)
            .padding(.top, 16)
        }
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

    private var tabBar: some View {
        HStack(spacing: 8) {
            ForEach(SettingsTab.allCases) { tab in
                TabSelectorButton(title: tab.title, isSelected: selectedTab == tab) {
                    selectedTab = tab
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .settings:
            settingsContent
        case .gameCenter:
            gameCenterContent
        case .stats:
            statsContent
        case .credits:
            creditsContent
        }
    }

    private var settingsContent: some View {
        VStack(spacing: 24) {
            Toggle("Sound", isOn: $music.soundOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.66, green: 0.20, blue: 0.27)))
                .foregroundColor(.white)
            Toggle("Music", isOn: $music.musicOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.66, green: 0.20, blue: 0.27)))
                .foregroundColor(.white)

            Button {
                MusicPlayer.shared.stopAll()
                router.push(.video)
            } label: {
                Text("Play Cutscene")
                    .font(.custom("TitilliumWeb-Bold", size: 24))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var gameCenterContent: some View {
        VStack(spacing: 24) {
            Button {
                showGameCenter = true
            } label: {
                Text("Leaderboards")
                    .font(.custom("TitilliumWeb-Bold", size: 24))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var statsContent: some View {
        List {
            HStack {
                Text("Coming soon!")
                    .font(.custom("TitilliumWeb-Bold", size: 18))
                Spacer()
            }
            .listRowBackground(Color.white.opacity(0.5))
        }
        .scrollContentBackground(.hidden)
    }

    private var creditsContent: some View {
        List(contributors) { profile in
            HStack {
                VStack(alignment: .leading) {
                    Text(profile.name)
                        .font(.custom("TitilliumWeb-Bold", size: 18))
                    Text(profile.role)
                        .font(.custom("TitilliumWeb-Light", size: 14))
                }
                Spacer()
                Image("\(profile.domain)Logo")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.red)
            }
            .contentShape(Rectangle())
            .onTapGesture { redirectPrompt = profile }
            .listRowBackground(Color.white.opacity(0.5))
        }
        .scrollContentBackground(.hidden)
    }
}
