//
//  EventLogger.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 10/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import FirebaseAnalytics
import Foundation

class EventLogger {
    
    static let shared = EventLogger()
    
    private init() {}
    
    func logCoinsInMatch(coins: Int) {
        Analytics.logEvent(AnalyticsEventEarnVirtualCurrency, parameters: [
            AnalyticsParameterVirtualCurrencyName: "coins",
            AnalyticsParameterValue: coins
        ])
    }
    
    private func getLevelName(playerCount: Int, difficulty: GameDifficulty) -> String {
        "\(playerCount) players - \(difficulty.rawValue)"
    }
    
    func logMatchStart(withPlayerCount playerCount: Int, andDifficulty difficulty: GameDifficulty) {
        
        let levelName = getLevelName(playerCount: playerCount, difficulty: difficulty)
        
        Analytics.logEvent(AnalyticsEventLevelStart, parameters: [
            AnalyticsParameterLevelName: levelName
        ])
    }
    
    func logMatchEnd(withPlayerCount playerCount: Int, andDifficulty difficulty: GameDifficulty, success: Bool = true) {
        
        let levelName = getLevelName(playerCount: playerCount, difficulty: difficulty)
        
        Analytics.logEvent(AnalyticsEventLevelEnd, parameters: [
            AnalyticsParameterLevelName: levelName,
            AnalyticsParameterSuccess: success
        ])
    }
    
    func logButtonPress(buttonName: String) {
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterItemID: "id-\(buttonName)",
            AnalyticsParameterContentType: "button"
        ])
    }
    
}
