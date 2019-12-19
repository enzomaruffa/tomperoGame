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
    
    // MARK: - Game Center
    var isGameCenterEnabled: Bool! // check if Game Center enabled
    var defaultLeaderboard = "" // check default leaderboard ID
    let LEADERBOARD_ID = "com.score.spacespice"
    
    // MARK: - Outlets
    @IBOutlet weak var deliveredOrdersLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        EventLogger.shared.logCoinsInMatch(coins: statistics.totalPoints)
        
        // Do any additional setup after loading the view.
        deliveredOrdersLabel.text = "\(statistics.totalDeliveredOrders) delivered orders!"
        
        pointsLabel.text = "\(statistics.totalPoints) points!"
        
        authenticateLocalPlayer()
        submitScoreToGameCenter()
    }
    
    // MARK: - Methods
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.local
        
        localPlayer.authenticateHandler = { (viewController, error) -> Void in
            if viewController != nil {
                // 1. show login if player is not logged in
                self.present(viewController!, animated: true, completion: nil)
            } else if localPlayer.isAuthenticated {
                // 2. player is already authenticated & logged in, load game center
                self.isGameCenterEnabled = true
                
                // get default leaderboard ID
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifer, error) in
                    if error != nil {
                        print(error)
                    } else {
                        self.defaultLeaderboard = leaderboardIdentifer!
                    }
                })
                
            } else {
                // 3. game center is not enabled on the users device
                self.isGameCenterEnabled = false
                print("Local player could not be authenticated!")
                print(error)
            }
        }
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Actions
    @IBAction func menuPressed(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "statistics-menu")
        
        coordinator?.popToRoot()
    }
    
    func submitScoreToGameCenter() {
        let score = GKScore(leaderboardIdentifier: LEADERBOARD_ID)
        score.value = Int64(statistics.totalPoints)
        GKScore.report([score]) { (error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("Best Score submitted to leaderboard!")
            }
        }
    }
    
    func openLeaderboard(_ sender: AnyObject) {
        let vc = GKGameCenterViewController()
        vc.gameCenterDelegate = self
        vc.viewState = .leaderboards
        vc.leaderboardIdentifier = LEADERBOARD_ID
        present(vc, animated: true, completion: nil)
    }
}
