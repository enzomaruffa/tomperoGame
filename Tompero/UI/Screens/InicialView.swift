//
//  InicialView.swift
//  Tompero
//
//  Main menu. Lays out the kombi background, JOIN / HOST buttons inside
//  its windows, the frog dialog at the bottom, and the top bar (coins,
//  name editor, settings) using the same absolute positions the legacy
//  `Main.storyboard` did. We treat the screen as a fixed 896×414 design
//  canvas (iPhone 11 landscape) and scale it to fit whatever device runs.
//

import SwiftUI

private let dialogIntro = """
Okay, okay…. I know this Food-Ship doesn’t look like the best investment in the galaxy, but you'll see. This lil' baby is gonna make it rain!
Oh! To begin working you need to go to the central food supply station. Who wants to drive? You can go in the front. The rest can sit in the back!
"""

private let dialogShort = "C'mon! Just GO!"

struct InicialView: View {
    @EnvironmentObject private var router: AppRouter

    @State private var dialogText: String = dialogIntro
    @State private var revealedCount: Int = 0
    @State private var lightsOn: Bool = false
    @State private var coinCount: Int = 0
    @State private var nameButtonTitle: String = LANConnectionManager.shared.selfName
    @State private var showNameEditor: Bool = false
    @State private var nameDraft: String = LocalPeerIdentity.userSetName ?? ""

    private let typingTimer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    private let blinkTimer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    // Design canvas — matches the storyboard's iPhone 11 landscape viewport.
    private static let designWidth: CGFloat = 896
    private static let designHeight: CGFloat = 414

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / Self.designWidth, proxy.size.height / Self.designHeight)
            let scaledWidth = Self.designWidth * scale
            let scaledHeight = Self.designHeight * scale
            let dx = (proxy.size.width - scaledWidth) / 2
            let dy = (proxy.size.height - scaledHeight) / 2

            ZStack {
                StarsBackground().ignoresSafeArea()

                ZStack {
                    // Kombi / spaceship background
                    designed(x: 125, y: 20, w: 646, h: 280, scale: scale) {
                        Image("nave")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }

                    // JOIN — sits over the front window of the kombi
                    designed(x: 278.5, y: 103, w: 64, h: 28, scale: scale) {
                        Button {
                            EventLogger.shared.logButtonPress(buttonName: "inicial-join")
                            dialogText = dialogShort
                            revealedCount = 0
                            router.push(.waitingRoom(hosting: false))
                        } label: {
                            Image(lightsOn ? "JOIN - brilhando" : "JOIN - apagado")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        .buttonStyle(.plain)
                    }

                    // HOST — sits over the back window of the kombi
                    designed(x: 599.5, y: 82, w: 93, h: 70, scale: scale) {
                        Button {
                            EventLogger.shared.logButtonPress(buttonName: "inicial-host")
                            dialogText = dialogShort
                            revealedCount = 0
                            router.push(.waitingRoom(hosting: true))
                        } label: {
                            Image(lightsOn ? "HOST - brilhando" : "HOST - apagado")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        .buttonStyle(.plain)
                    }

                    // Bottom: frog character — bottom section starts at y=270
                    // in the storyboard, so the frog's (81, 16) becomes (125, 286)
                    designed(x: 125, y: 286, w: 116, h: 96, scale: scale) {
                        Image("sapao")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }

                    // Dialog box bubble
                    designed(x: 205, y: 243, w: 648, h: 182, scale: scale) {
                        Image("caixa de texto")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }

                    // Dialog text inside the bubble — tapping advances to the end
                    designed(x: 292.5, y: 286, w: 511, h: 96, scale: scale) {
                        Text(String(dialogText.prefix(revealedCount)))
                            .font(.custom("TitilliumWeb-Bold", size: 17 * scale))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                revealedCount = dialogText.count
                            }
                    }

                    // Coin icon
                    designed(x: 54, y: 17, w: 65, h: 65, scale: scale) {
                        Image("Coin")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }

                    // Coin count label
                    designed(x: 129, y: 17, w: 319, h: 65, scale: scale) {
                        Text("\(coinCount)")
                            .font(.custom("TitilliumWeb-Bold", size: 30 * scale))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    }

                    // Name editor — pill slotted in the gap between the coin
                    // label (ends ~x=448) and the settings gear (starts at
                    // x=791). Uses the same `Settings_selectionButtonOFF`
                    // pill art the Settings tab strip uses, so it visually
                    // belongs in the world. Sized to match the storyboard's
                    // OFF-state pill at 208.5×47.5.
                    designed(x: 519, y: 26, w: 208.5, h: 47.5, scale: scale) {
                        Button {
                            nameDraft = LocalPeerIdentity.userSetName ?? ""
                            showNameEditor = true
                        } label: {
                            ZStack {
                                Image("Settings_selectionButtonOFF")
                                    .resizable()
                                    .scaledToFit()
                                Text("👤 \(nameButtonTitle)")
                                    .font(.custom("TitilliumWeb-Bold", size: 16 * scale))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                    .padding(.horizontal, 16 * scale)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // Settings gear, top-right
                    designed(x: 791, y: 20, w: 61, h: 59, scale: scale) {
                        Button {
                            router.push(.settings)
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: scaledWidth, height: scaledHeight)
                .offset(x: dx, y: dy)
            }
        }
        .onAppear {
            Log.game.info("LAUNCH +\(AppDelegate.elapsed())s InicialView.onAppear")
            revealedCount = 0
            fetchCoinCount()
            // Game Center authentication is deferred to the first place that
            // actually needs it (Statistics → leaderboard submission). Doing
            // it here was blocking the main thread on the simulator for
            // 10–15s while iOS waited for the gamed XPC to time out.
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

    // MARK: - Layout helper

    /// Places `content` at the storyboard-style frame `(x, y, w, h)` inside
    /// the design canvas. Pre-scales the frame and uses `.position()` (which
    /// expects the center).
    @ViewBuilder
    private func designed<V: View>(
        x: CGFloat,
        y: CGFloat,
        w: CGFloat,
        h: CGFloat,
        scale: CGFloat,
        @ViewBuilder content: () -> V
    ) -> some View {
        content()
            .frame(width: w * scale, height: h * scale)
            .position(x: (x + w / 2) * scale, y: (y + h / 2) * scale)
    }

    // MARK: - Side effects

    private func fetchCoinCount() {
        CloudKitManager.shared.getPlayerCoinCount { count in
            DispatchQueue.main.async {
                coinCount = count
            }
        }
    }
}
