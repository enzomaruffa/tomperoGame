//
//  Log.swift
//  Tompero
//
//  Thin os.Logger facade. Subsystem strings are namespaced per concern so
//  Console.app can filter cleanly, and `.debug` lines are stripped from
//  release builds automatically by the OS framework.
//

import Foundation
import os

enum Log {
    private static let subsystem = "com.enzomaruffa.spacespice"

    static let network = Logger(subsystem: subsystem, category: "network")
    static let game = Logger(subsystem: subsystem, category: "game")
    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let analytics = Logger(subsystem: subsystem, category: "analytics")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
