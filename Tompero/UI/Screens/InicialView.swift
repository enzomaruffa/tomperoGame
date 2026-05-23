//
//  InicialView.swift
//  Tompero
//

import SwiftUI

struct InicialView: View {
    var body: some View {
        ZStack {
            StarsBackground().ignoresSafeArea()
            Text("Inicial — TODO")
                .foregroundColor(.white)
        }
    }
}
