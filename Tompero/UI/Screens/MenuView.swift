//
//  MenuView.swift
//  Tompero
//

import SwiftUI

struct MenuView: View {
    var body: some View {
        ZStack {
            StarsBackground().ignoresSafeArea()
            Text("Menu — TODO")
                .foregroundColor(.white)
        }
    }
}
