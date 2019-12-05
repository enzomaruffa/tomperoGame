//
//  MovableDelegate.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 30/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import CoreGraphics

protocol MovableDelegate: class {
    // Moves and returns if the movement is possible
    var currentStation: StationNode { get set }
    func moveStarted(currentPosition: CGPoint)
    func moving(currentPosition: CGPoint)
    func moveEnded(currentPosition: CGPoint)
    func attemptMove(to station: StationNode) -> Bool
}
