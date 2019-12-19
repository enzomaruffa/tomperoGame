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
        #if !DEBUG
        Analytics.logEvent(AnalyticsEventEarnVirtualCurrency, parameters: [
            AnalyticsParameterVirtualCurrencyName: "coins",
            AnalyticsParameterValue: coins
        ])
        #endif
    }
    
    private func getLevelName(playerCount: Int, difficulty: GameDifficulty) -> String {
        "\(playerCount) players - \(difficulty.rawValue)"
    }
    
    func logMatchStart(withPlayerCount playerCount: Int, andDifficulty difficulty: GameDifficulty) {
        
        #if !DEBUG
        let levelName = getLevelName(playerCount: playerCount, difficulty: difficulty)
        
        Analytics.logEvent(AnalyticsEventLevelStart, parameters: [
            AnalyticsParameterLevelName: levelName
        ])
        #endif
    }
    
    func logMatchEnd(withPlayerCount playerCount: Int, andDifficulty difficulty: GameDifficulty, success: Bool = true) {
        
        #if !DEBUG
        let levelName = getLevelName(playerCount: playerCount, difficulty: difficulty)
        
        Analytics.logEvent(AnalyticsEventLevelEnd, parameters: [
            AnalyticsParameterLevelName: levelName,
            AnalyticsParameterSuccess: success
        ])
        #endif
    }
    
    func logButtonPress(buttonName: String) {
        #if !DEBUG
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterItemID: "id-\(buttonName)",
            AnalyticsParameterContentType: "button"
        ])
        #endif
    }
    
}
