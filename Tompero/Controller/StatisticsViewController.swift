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
    let easyID = "com.spacespice.easy"
    let mediumID = "com.spacespice.medium"
    let hardID = "com.spacespice.hard"
    
    // MARK: - Outlets
    @IBOutlet weak var ordersLabel: UILabel!
    @IBOutlet weak var coinsLabel: UILabel!
    @IBOutlet weak var gameOverLabel: UILabel!
    @IBOutlet weak var mainMenuButton: UIButton!
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let labelMultiplier: CGFloat = traitCollection.verticalSizeClass == .regular ? 0.4/11.3 : 0.6/9.5
        let labelFontSize: CGFloat = (self.view.frame.height * labelMultiplier).rounded(.down)
        ordersLabel.font = UIFont(name: "TitilliumWeb-Bold", size: labelFontSize)
        coinsLabel.font = UIFont(name: "TitilliumWeb-Bold", size: labelFontSize)
        
        let titleMultiplier: CGFloat = traitCollection.verticalSizeClass == .regular ? 0.4/10.7 : 0.6/8.8
        let titleFontSize: CGFloat = (self.view.frame.height * titleMultiplier).rounded(.down)
        gameOverLabel.font = UIFont(name: "TitilliumWeb-Bold", size: titleFontSize)
        
        let buttonMultiplier: CGFloat = traitCollection.verticalSizeClass == .regular ? 0.4/12.8 : 0.6/11.2
        let buttonFontSize: CGFloat = (self.view.frame.height * buttonMultiplier).rounded(.down)
        mainMenuButton.titleLabel!.font = UIFont(name: "TitilliumWeb-Bold", size: buttonFontSize)
        
        EventLogger.shared.logCoinsInMatch(coins: statistics.totalPoints)
        
        databaseManager.addNewMatch(withHash: statistics.matchHash, coinCount: statistics.totalPoints)
        
        // Do any additional setup after loading the view.
        ordersLabel.text = "\(statistics.totalDeliveredOrders) orders delivered!"
        
        coinsLabel.text = "\(statistics.totalPoints) coins earned!"
        
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
