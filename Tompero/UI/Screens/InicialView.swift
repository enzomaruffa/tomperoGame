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
    // Empty until .onAppear so we don't force `LANConnectionManager.init()`
    // (which allocates the listener / browser + registers lifecycle
    // observers) during the InicialView struct's init — that ran on the
    // first-frame critical path before this change.
    @State private var nameButtonTitle: String = ""
    @State private var showNameEditor: Bool = false
    @State private var nameDraft: String = LocalPeerIdentity.userSetName ?? ""

    private let typingTimer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    private let blinkTimer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    // Design canvas — matches the storyboard's iPhone 11 landscape viewport.
    private static let designWidth: CGFloat = 896
    private static let designHeight: CGFloat = 414

    // Fires exactly once (lazy static) the first time SwiftUI evaluates the
    // body, even though `body` itself is re-invoked many times per frame.
    private static let bodyTimer: Void = {
        Log.game.info("LAUNCH +\(AppDelegate.elapsed())s InicialView.body first eval")
    }()

    var body: some View {
        _ = Self.bodyTimer
        return GeometryReader { proxy in
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
                        .buttonStyle(PressableButtonStyle())
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
                        .buttonStyle(PressableButtonStyle())
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

                    // Coin balance — icon + count grouped on a dark capsule so
                    // the number stays readable over the bright sky and the
                    // top HUD row (coins / name tag / gear) reads as one set.
                    // `.numericText()` rolls the digits when fetchCoinCount lands.
                    designed(x: 44, y: 17, w: 188, h: 56, scale: scale) {
                        HStack(spacing: 8 * scale) {
                            Image("Coin")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40 * scale, height: 40 * scale)
                            Text("\(coinCount)")
                                .font(.custom("TitilliumWeb-Bold", size: 26 * scale))
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12 * scale)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.13, green: 0.11, blue: 0.26))
                                .overlay(Capsule().stroke(Color.white.opacity(0.55), lineWidth: 2 * scale))
                        )
                    }

                    // Name tag — a solid "ID badge" centered in the gap
                    // between the coin label (ends ~x=448) and the settings
                    // gear (x=791), vertically aligned with the top row. Solid
                    // opaque capsule (no see-through art over the starfield)
                    // with a person glyph + pencil affordance signalling it's
                    // editable.
                    designed(x: 500, y: 22, w: 238, h: 50, scale: scale) {
                        Button {
                            nameDraft = LocalPeerIdentity.userSetName ?? ""
                            showNameEditor = true
                        } label: {
                            HStack(spacing: 8 * scale) {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 26 * scale, height: 26 * scale)
                                    .foregroundColor(.white.opacity(0.9))
                                Text(nameButtonTitle)
                                    .font(.custom("TitilliumWeb-Bold", size: 17 * scale))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                Spacer(minLength: 0)
                                Image(systemName: "pencil")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16 * scale, height: 16 * scale)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 16 * scale)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.13, green: 0.11, blue: 0.26))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.55), lineWidth: 2 * scale))
                            )
                        }
                        .buttonStyle(PressableButtonStyle())
                    }

                    // Settings gear, top-right — seated in a dark circular
                    // button so it reads as part of the HUD instead of a bare
                    // white system glyph floating over the starfield (matches
                    // the name tag's dark/bordered treatment).
                    designed(x: 791, y: 20, w: 61, h: 59, scale: scale) {
                        Button {
                            router.push(.settings)
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .scaledToFit()
                                .padding(13 * scale)
                                .foregroundColor(.white.opacity(0.92))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(
                                    Circle()
                                        .fill(Color(red: 0.13, green: 0.11, blue: 0.26))
                                        .overlay(Circle().stroke(Color.white.opacity(0.55), lineWidth: 2 * scale))
                                )
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .frame(width: scaledWidth, height: scaledHeight)
                .offset(x: dx, y: dy)
            }
        }
        .onAppear {
            Log.game.info("LAUNCH +\(AppDelegate.elapsed())s InicialView.onAppear")
            revealedCount = 0
            // Lazy: forces LANConnectionManager.init() the first time. Doing
            // this here (not in the @State initializer) keeps it off the
            // first-frame critical path.
            nameButtonTitle = LANConnectionManager.shared.selfName
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
        Task {
            let count = await CloudKitManager.shared.getPlayerCoinCount()
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.8)) {
                    coinCount = count
                }
            }
        }
    }
}
