//
//  StatisticsViewController.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 08/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import UIKit
import GameKit

class StatisticsViewController: UIViewController, Storyboarded, GKGameCenterControllerDelegate {
    
    // MARK: - Storyboarded
    static var storyboardName: String = "Statistics"
    
    // MARK: - Coordinator
    weak var coordinator: MainCoordinator?
    
    // MARK: - Variables
    var statistics: MatchStatistics!
    let databaseManager: DatabaseManager = CloudKitManager.shared
    let debugLogger = ConsoleDebugLogger.shared
    
    // MARK: - Game Center
    var isGameCenterEnabled: Bool! // check if Game Center enabled
    var defaultLeaderboard = "" // check default leaderboard ID
    let easyID = "com.spacespice.easy"
    let mediumID = "com.spacespice.medium"
    let hardID = "com.spacespice.hard"
    
    // MARK: - Outlets
    @IBOutlet weak var deliveredOrdersLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        EventLogger.shared.logCoinsInMatch(coins: statistics.totalPoints)
        
        databaseManager.addNewMatch(withHash: statistics.matchHash, coinCount: statistics.totalPoints)
        
        // Do any additional setup after loading the view.
        deliveredOrdersLabel.text = "\(statistics.totalDeliveredOrders) orders delivered!"
        
        pointsLabel.text = "\(statistics.totalPoints) points earned!"
        
        submitScoreToGameCenter()
    }
    
    // MARK: - Methods
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    func submitScoreToGameCenter() {
        var leaderboardID = ""
        switch statistics.ruleUsed.difficulty {
        case .easy: leaderboardID = easyID
        case .medium: leaderboardID = mediumID
        case .hard: leaderboardID = hardID
        }
        let score = GKScore(leaderboardIdentifier: leaderboardID)
        score.value = Int64(statistics.totalPoints)
        GKScore.report([score]) { (error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("Best Score submitted to leaderboard!")
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func menuPressed(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "statistics-menu")
        
        coordinator?.popToRoot()
    }
}
