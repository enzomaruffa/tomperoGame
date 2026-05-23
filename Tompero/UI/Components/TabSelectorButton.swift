//
//  TabSelectorButton.swift
//  Tompero
//
//  Settings-screen tab button. Mirrors the legacy UIKit `SelectorButton`
//  font + image swap on selection.
//

import SwiftUI

struct TabSelectorButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Image(isSelected ? "Settings_selectionButtonON" : "Settings_selectionButtonOFF")
                    .resizable()
                    .scaledToFit()
                Text(title)
                    .font(.custom(isSelected ? "TitilliumWeb-Bold" : "TitilliumWeb-Light", size: isSelected ? 22 : 16))
                    .foregroundColor(.white)
            }
            .frame(width: isSelected ? 140 : 100, height: 60)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
