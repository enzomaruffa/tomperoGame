//
//  DesignCanvas.swift
//  Tompero
//
//  Helper that mirrors the original storyboards' 896×414 design canvas
//  (iPhone 11 landscape viewport). Every screen overlays its content on the
//  shared `WR_bgFront` red background and uses storyboard-style top-left
//  frames via the `designed(x:y:w:h:)` modifier.
//

import SwiftUI

extension View {
    /// Place this view at the storyboard top-left frame `(x, y, w, h)` inside
    /// the design canvas, scaled to fit the actual device. `designScale` is
    /// computed by the surrounding `DesignCanvas`.
    func designed(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, scale: CGFloat) -> some View {
        self
            .frame(width: w * scale, height: h * scale)
            .position(x: (x + w / 2) * scale, y: (y + h / 2) * scale)
    }
}

struct DesignCanvas<Content: View>: View {
    static var designWidth: CGFloat { 896 }
    static var designHeight: CGFloat { 414 }

    /// Whether to overlay the standard red `WR_bgFront` background. Disable
    /// for the Inicial screen which has its own kombi background.
    let showRedOverlay: Bool

    @ViewBuilder var content: (CGFloat) -> Content

    init(showRedOverlay: Bool = true, @ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.showRedOverlay = showRedOverlay
        self.content = content
    }

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
                    if showRedOverlay {
                        Image("WR_bgFront")
                            .resizable()
                            .scaledToFill()
                            .frame(width: scaledWidth, height: scaledHeight)
                    }
                    content(scale)
                }
                .frame(width: scaledWidth, height: scaledHeight)
                .offset(x: dx, y: dy)
            }
        }
    }
}

/// Shared top header (back button + title + optional right-side button).
/// Matches the `HeaderView` block used by Settings, WaitingRoom, and Menu in
/// the original storyboards.
struct HeaderBar: View {
    let title: String
    let scale: CGFloat
    let onBack: () -> Void
    var rightAccessory: AnyView? = nil

    var body: some View {
        Group {
            // Back button — original frame (4, 16, 63.5, 59) within HeaderView at (44, 0)
            Button(action: onBack) {
                Image("WR_backButton")
                    .resizable()
                    .scaledToFit()
            }
            .buttonStyle(.plain)
            .designed(x: 48, y: 16, w: 63.5, h: 59, scale: scale)

            // Title label — original (283, 20, 242, 53) inside HeaderView (44, 0)
            Text(title)
                .font(.custom("TitilliumWeb-Bold", size: 40 * scale))
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .designed(x: 327, y: 20, w: 242, h: 53, scale: scale)

            if let rightAccessory {
                rightAccessory
            }
        }
    }
}
