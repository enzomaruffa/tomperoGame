//
//  MenuView.swift
//  Tompero
//
//  Recipe overview. Two static page images in a paged TabView, with the
//  stars background.
//

import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var page: Int = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            StarsBackground().ignoresSafeArea()

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
            .padding(.horizontal)

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
    }
}
