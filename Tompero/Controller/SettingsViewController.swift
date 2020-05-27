//
//  SettingsViewController.swift
//  Tompero
//
//  Created by Vinícius Binder on 26/05/20.
//  Copyright © 2020 Tompero. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, Storyboarded {
    
    static var storyboardName = "Settings"
    weak var coordinator: MainCoordinator?

    @IBOutlet weak var boxCenterYConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = boxCenterYConstraint.setMultiplier(multiplier: traitCollection.verticalSizeClass == .regular ? 1 : 1.15)
        
    }

    @IBAction func backPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
