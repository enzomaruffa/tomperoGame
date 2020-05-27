//
//  SettingsViewController.swift
//  Tompero
//
//  Created by Vinícius Binder on 26/05/20.
//  Copyright © 2020 Tompero. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, Storyboarded {
    
    // MARK: - Coordinator
    static var storyboardName = "Settings"
    weak var coordinator: MainCoordinator?
    
    // MARK: - Outlets
    @IBOutlet weak var boxCenterYConstraint: NSLayoutConstraint!
    @IBOutlet var widthConstraints: [NSLayoutConstraint]!
    @IBOutlet var buttons: [SelectorButton]!
    @IBOutlet var images: [UIImageView]!
    
    // MARK: - Variables
    
    // MARK: - Constants
    let selectedFont = UIFont(name: "TitilliumWeb-Bold", size: 26)
    let defaultFont = UIFont(name: "TitilliumWeb-Light", size: 19)
    let selectedMultiplier: CGFloat = 0.31
    let defaultMultiplier: CGFloat = 0.23
    
    // MARK: - Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = boxCenterYConstraint.setMultiplier(multiplier: traitCollection.verticalSizeClass == .regular ? 1 : 1.15)
        
        buttons.enumerated().forEach { index, button in
            button.image = self.images[index]
            if traitCollection.verticalSizeClass == .regular {
                button.defaultFont = UIFont(name: "TitilliumWeb-Light", size: 32)
                button.selectedFont = UIFont(name: "TitilliumWeb-Bold", size: 44)
            } else {
                button.defaultFont = UIFont(name: "TitilliumWeb-Light", size: 19)
                button.selectedFont = UIFont(name: "TitilliumWeb-Bold", size: 26)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        select(0)
    }
    
    @IBAction func backPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func select(_ tag: Int) {
        
        widthConstraints.enumerated().forEach { index, constraint in
            _ = constraint.setMultiplier(multiplier: index == tag ? selectedMultiplier : defaultMultiplier)
            UIView.animate(withDuration: 0.1) {
                self.view.layoutIfNeeded()
            }
        }
        
        buttons.enumerated().forEach { index, button in
            button.isEnabled = !(index == tag)
        }
        
        // change the view too
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        select((sender as! UIButton).tag)
    }
    
}
