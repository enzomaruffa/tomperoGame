//
//  WaitingRoomView.swift
//  Tompero
//

import SwiftUI

struct WaitingRoomView: View {
    let hosting: Bool

    var body: some View {
        ZStack {
            StarsBackground().ignoresSafeArea()
            Text("Waiting Room — TODO (hosting: \(hosting ? "yes" : "no"))")
                .foregroundColor(.white)
        }
    }
}
