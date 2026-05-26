//
//  TappableClosure.swift
//  Tompero
//
//  Wraps a closure as a `TappableDelegate` so a `TappableSpriteNode` can
//  fire an arbitrary action on tap without a bespoke delegate class.
//

import Foundation

final class TappableClosure: TappableDelegate {
    private let handler: () -> Void

    init(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    func tap() {
        handler()
    }
}
