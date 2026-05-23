//
//  MenuView.swift
//  Tompero
//
//  Recipe-book overview. Layout matches MenuStoryboard.storyboard:
//  red background, header, side decoration overlays, and a horizontal
//  pager between two recipe pages.
//

import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var page: Int = 0

    var body: some View {
        DesignCanvas { scale in
            // Header with back button (no title text — uses Menu_label image instead)
            Button {
                router.pop()
            } label: {
                Image("WR_backButton")
                    .resizable()
                    .scaledToFit()
            }
            .buttonStyle(.plain)
            .designed(x: 48, y: 16, w: 63.5, h: 59, scale: scale)

            // "MENU" image label inside the header (606, 25, 192, 43) absolute (650, 25)
            Image("Menu_label")
                .resizable()
                .scaledToFit()
                .designed(x: 650, y: 25, w: 192, h: 43, scale: scale)

            // Side decorations
            Image("Menu_detailLeft")
                .resizable()
                .scaledToFit()
                .designed(x: 44, y: 205.5, w: 105.5, h: 208.5, scale: scale)
            Image("Menu_detailRight")
                .resizable()
                .scaledToFit()
                .designed(x: 584, y: 294, w: 268, h: 120, scale: scale)

            // Pager (112.5, 73, 671, 287) — inside it the pages are 671×245
            // starting at y=21 → absolute (112.5, 94, 671, 245)
            TabView(selection: $page) {
                Image("Menu_page1")
                    .resizable()
                    .scaledToFit()
                    .tag(0)
                Image("Menu_page2")
                    .resizable()
                    .scaledToFit()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .designed(x: 112.5, y: 94, w: 671, h: 245, scale: scale)
        }
    }
}
