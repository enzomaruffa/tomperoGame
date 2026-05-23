//
//  WipeTransition.swift
//  Tompero
//
//  Recreates the legacy UIKit `WipeTransition` as a SwiftUI `AnyTransition`
//  so screens preserve the slide-from-trailing-edge visual identity. Apply
//  to view bodies via `.transition(.wipe)`; the `AppRouter` wraps the push /
//  pop calls in `withAnimation(.easeInOut(duration: 0.5))` so the transition
//  drives off the navigation path mutation.
//

import SwiftUI

extension AnyTransition {
    /// Asymmetric slide: pushed screens insert from the trailing edge,
    /// popped screens remove toward the trailing edge.
    static var wipe: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .trailing)
        )
    }
}
