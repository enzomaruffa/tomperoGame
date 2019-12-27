//
//  StatisticsViewController.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 08/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import UIKit

class StatisticsViewController: UIViewController, Storyboarded {
    
    // MARK: - Storyboarded
    static var storyboardName: String = "Statistics"
    
    // MARK: - Coordinator
    weak var coordinator: MainCoordinator?
    
    // MARK: - Variables
    var statistics: MatchStatistics!
    let databaseManager: DatabaseManager = CloudKitManager.shared
    
    // MARK: - Outlets
    @IBOutlet weak var deliveredOrdersLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        EventLogger.shared.logCoinsInMatch(coins: statistics.totalPoints)
        databaseManager.addNewMatch(withHash: statistics.matchHash, coinCount: statistics.totalPoints)
        
        // Do any additional setup after loading the view.
        deliveredOrdersLabel.text = "\(statistics.totalDeliveredOrders) delivered orders!"
        
        pointsLabel.text = "\(statistics.totalPoints) points!"
    }
    
    // MARK: - Methods
    
    // MARK: - Actions
    @IBAction func menuPressed(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "statistics-menu")
        
        coordinator?.popToRoot()
    }
    
}
