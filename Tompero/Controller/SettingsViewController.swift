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
    @IBOutlet var views: [UIView]!
    @IBOutlet var labels: [UILabel]!
    
    // Settings
    @IBOutlet weak var soundSwitch: UISwitch!
    @IBOutlet weak var musicSwitch: UISwitch!
    @IBOutlet weak var cutsceneButton: UIButton!
    
    // MARK: - Variables
    var currentView: UIView!
    
    // MARK: - Constants
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
        
        soundSwitch.isOn = CustomAudioPlayer.soundOn
        musicSwitch.isOn = MusicPlayer.musicOn
        cutsceneButton.titleLabel!.font = UIFont(name: "TitilliumWeb-Bold", size: defaultSize)
        labels.forEach { label in
            label.font = UIFont(name: "TitilliumWeb-Bold", size: selectedSize)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        MusicPlayer.shared.play(.menu)
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
        
        views.enumerated().forEach { index, view in
            view.isHidden = !(index == tag)
        }
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        select((sender as! UIButton).tag)
    }
    
    @IBAction func soundTapped(_ sender: Any) {
        CustomAudioPlayer.soundOn.toggle()
    }
    
    @IBAction func musicTapped(_ sender: Any) {
        MusicPlayer.musicOn.toggle()
        if MusicPlayer.musicOn {
            MusicPlayer.shared.play(.menu)
        } else {
            MusicPlayer.shared.stopAll()
        }
    }
    
    @IBAction func cutsceneTapped(_ sender: Any) {
        MusicPlayer.shared.stopAll()
        coordinator?.video()
    }
}
