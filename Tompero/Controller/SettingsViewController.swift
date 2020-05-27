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
    @IBOutlet weak var box: UIView!
    
    // MARK: - Variables
    var currentView: UIView!
    
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
        }
        
        let selectorWidth = self.view.frame.width * 0.85 / 8
        let defaultSize = (selectorWidth * defaultMultiplier).rounded(.down)
        let selectedSize = (selectorWidth * selectedMultiplier).rounded(.down)
        buttons.forEach { button in
            button.defaultFont = UIFont(name: "TitilliumWeb-Light", size: defaultSize)
            button.selectedFont = UIFont(name: "TitilliumWeb-Bold", size: selectedSize)
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
        
        loadView(tag)
    }
    
    func loadView(_ tag: Int) {
        if currentView != nil {
            currentView.removeFromSuperview()
        }
        
        switch tag {
        case 1: currentView = GameCenterView.instantiate()
        case 2: currentView = StatsView.instantiate()
        case 3: currentView = CreditsView.instantiate()
        default: currentView = SettingsView.instantiate()
        }
        
        currentView.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(currentView)
        
        NSLayoutConstraint.activate([
            currentView.topAnchor.constraint(equalTo: box.topAnchor),
            currentView.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            currentView.widthAnchor.constraint(equalTo: box.widthAnchor, multiplier: 0.975),
            currentView.heightAnchor.constraint(equalTo: box.heightAnchor, multiplier: 0.86)
        ])
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        select((sender as! UIButton).tag)
    }
    
}
