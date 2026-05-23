//
//  InicialView.swift
//  Tompero
//
//  Main menu. Replaces the storyboard-driven InicialViewController with
//  native SwiftUI: typing dialog animation, blinking host / join lights,
//  centered name editor button, GameKit auth + coin count fetch on appear.
//

import SwiftUI
import GameKit

private let dialogIntro = """
Okay, okay…. I know this Food-Ship doesn’t look like the best investment in the galaxy, but you'll see. This lil' baby is gonna make it rain!
Oh! To begin working you need to go to the central food supply station. Who wants to drive? You can go in the front. The rest can sit in the back!
"""

private let dialogShort = "C'mon! Just GO!"

struct InicialView: View {
    @EnvironmentObject private var router: AppRouter

    // Typing animation: revealed prefix length grows once per timer tick
    // until the full message is rendered.
    @State private var dialogText: String = dialogIntro
    @State private var revealedCount: Int = 0

    // Light blink: host / join images cycle through "apagado" / "brilhando"
    // every 0.6s while on this screen.
    @State private var lightsOn: Bool = false

    @State private var coinCount: Int = 0
    @State private var nameButtonTitle: String = LANConnectionManager.shared.selfName
    @State private var showNameEditor: Bool = false
    @State private var nameDraft: String = LocalPeerIdentity.userSetName ?? ""

    private let typingTimer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    private let blinkTimer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .top) {
            StarsBackground().ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()
                HStack(spacing: 40) {
                    joinHost(image: lightsOn ? "JOIN - brilhando" : "JOIN - apagado") {
                        EventLogger.shared.logButtonPress(buttonName: "inicial-join")
                        dialogText = dialogShort
                        revealedCount = 0
                        router.push(.waitingRoom(hosting: false))
                    }
                    joinHost(image: lightsOn ? "HOST - brilhando" : "HOST - apagado") {
                        EventLogger.shared.logButtonPress(buttonName: "inicial-host")
                        dialogText = dialogShort
                        revealedCount = 0
                        router.push(.waitingRoom(hosting: true))
                    }
                }
                Spacer()
                dialogBox
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
            }

            topBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
        }
        .onAppear {
            revealedCount = 0
            authenticate()
            fetchCoinCount()
        }
        .onReceive(typingTimer) { _ in
            if revealedCount < dialogText.count {
                revealedCount += 1
            }
        }
        .onReceive(blinkTimer) { _ in
            lightsOn.toggle()
        }
        .alert(String(localized: "name.title"), isPresented: $showNameEditor) {
            TextField(UIDevice.current.name, text: $nameDraft)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
            Button(String(localized: "alert.cancel"), role: .cancel) {}
            Button(String(localized: "name.save")) {
                LocalPeerIdentity.setUserSetName(nameDraft)
                LANConnectionManager.shared.resetSession()
                nameButtonTitle = LANConnectionManager.shared.selfName
            }
        } message: {
            Text(String(localized: "name.message"))
        }
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack(alignment: .top) {
            HStack(spacing: 8) {
                Image(systemName: "creditcard.circle.fill")
                    .foregroundColor(.yellow)
                Text("\(coinCount)")
                    .font(.custom("TitilliumWeb-Bold", size: 24))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.35))
            .cornerRadius(12)

            Spacer()

            Button {
                nameDraft = LocalPeerIdentity.userSetName ?? ""
                showNameEditor = true
            } label: {
                Text("👤 \(nameButtonTitle)")
                    .font(.custom("TitilliumWeb-Bold", size: 18))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(12)
            }

            Spacer()

            Button {
                router.push(.settings)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
            }
        }
    }

    @ViewBuilder
    private func joinHost(image: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 160)
        }
        .buttonStyle(.plain)
    }

    private var dialogBox: some View {
        ZStack(alignment: .leading) {
            Image("caixa de texto")
                .resizable()
                .scaledToFit()
            HStack(alignment: .top, spacing: 12) {
                Image("sapao")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                Text(String(dialogText.prefix(revealedCount)))
                    .font(.custom("TitilliumWeb-Bold", size: 17))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Reveal the whole message immediately on tap.
            revealedCount = dialogText.count
        }
    }

    // MARK: - Side effects

    private func authenticate() {
        let player = GKLocalPlayer.local
        player.authenticateHandler = { _, error in
            if let error {
                Log.game.error("GameKit auth failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func fetchCoinCount() {
        CloudKitManager.shared.getPlayerCoinCount { count in
            DispatchQueue.main.async {
                coinCount = count
            }
        }
    }
}
