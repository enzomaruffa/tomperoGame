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
    
    // MARK: - Outlets
    @IBOutlet weak var deliveredOrdersLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
        deliveredOrdersLabel.text = "\(statistics.totalDeliveredOrders) delivered orders!"
        
        pointsLabel.text = "\(statistics.totalPoints) delivered orders!"
    }
    
    // MARK: - Methods
    
    // MARK: - Actions
    @IBAction func menuPressed(_ sender: Any) {
        coordinator?.popToRoot()
    }
    
    
}
