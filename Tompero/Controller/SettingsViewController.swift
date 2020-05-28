//
//  SettingsViewController.swift
//  Tompero
//
//  Created by Vinícius Binder on 26/05/20.
//  Copyright © 2020 Tompero. All rights reserved.
//

import UIKit
import GameKit

class SettingsViewController: UIViewController, Storyboarded, GKGameCenterControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
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
    @IBOutlet weak var statsTableView: UITableView!
    @IBOutlet weak var creditsTableView: UITableView!
    
    // Settings
    @IBOutlet weak var soundSwitch: UISwitch!
    @IBOutlet weak var musicSwitch: UISwitch!
    @IBOutlet var labelButtons: [UIButton]!
    
    // MARK: - Variables
    var currentView: UIView!
    var selectedFontSize: CGFloat!
    var defaultFontSize: CGFloat!
    
    // MARK: - Constants
    let selectedMultiplier: CGFloat = 0.31
    let defaultMultiplier: CGFloat = 0.23
    
    struct ContributorProfile {
        let name: String
        let role: String
        let url: String
        let domain: String
    }
    
    private let profiles: [ContributorProfile] = [
        ContributorProfile(name: "Flavio Akira Tsukamoto", role: "Developer", url: "https://www.linkedin.com/in/akiratsu/", domain: "LinkedIn"),
        ContributorProfile(name: "Enzo Maruffa Moreira", role: "Developer", url: "https://www.linkedin.com/in/enzomaruffa/", domain: "LinkedIn"),
        ContributorProfile(name: "Leonardo Palinkas", role: "Artist", url: "https://www.behance.net/palinkas3239", domain: "Behance"),
        ContributorProfile(name: "Vinícius Binder", role: "Developer", url: "https://www.linkedin.com/in/viniciusbinder/", domain: "LinkedIn"),
        ContributorProfile(name: "Diego Pontes", role: "Sound Design & Music", url: "https://www.linkedin.com/in/diego-pontes/", domain: "LinkedIn")
    ]
    
    // MARK: - Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = boxCenterYConstraint.setMultiplier(multiplier: traitCollection.verticalSizeClass == .regular ? 1 : 1.15)
        
        buttons.enumerated().forEach { index, button in
            button.image = self.images[index]
        }
        
        let selectorWidth = self.view.frame.width * 0.85 / 8
        defaultFontSize = (selectorWidth * defaultMultiplier).rounded(.down)
        selectedFontSize = (selectorWidth * selectedMultiplier).rounded(.down)
        buttons.forEach { button in
            button.defaultFont = UIFont(name: "TitilliumWeb-Light", size: defaultFontSize)
            button.selectedFont = UIFont(name: "TitilliumWeb-Bold", size: selectedFontSize)
        }
        
        soundSwitch.isOn = CustomAudioPlayer.soundOn
        musicSwitch.isOn = MusicPlayer.musicOn
        labelButtons.forEach { button in
            button.titleLabel!.font = UIFont(name: "TitilliumWeb-Bold", size: defaultFontSize)
        }
        labels.forEach { label in
            label.font = UIFont(name: "TitilliumWeb-Bold", size: selectedFontSize)
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
    
    // MARK: - Game Center
    @IBAction func leaderboardsTapped(_ sender: Any) {
        let newVC = GKGameCenterViewController()
        newVC.gameCenterDelegate = self
        newVC.viewState = .default
        present(newVC, animated: true, completion: nil)
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === creditsTableView {
            return profiles.count
        } else if tableView === statsTableView {
            return 0
        }
        switch tableView {
        case creditsTableView: return profiles.count
        case statsTableView: return 0
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === creditsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CreditsCell", for: indexPath) as! CreditsCell

            let profile = profiles[indexPath.row]
            cell.nameLabel.text = profile.name
            cell.roleLabel.text = profile.role
            cell.domainImageView.image = UIImage(named: "\(profile.domain)Logo")?.withRenderingMode(.alwaysTemplate)
            
            cell.nameLabel.font = UIFont(name: "TitilliumWeb-Bold", size: (selectedFontSize / 2).rounded(.up))
            cell.roleLabel.font = UIFont(name: "TitilliumWeb-Light", size: (selectedFontSize / 2).rounded(.up))
            
            cell.backgroundColor = indexPath.row % 2 == 0 ? #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 0.5047356592) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
            
            return cell
        } else if tableView === statsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StatsCell", for: indexPath) as! StatsCell
            
            // put stuff
            
            cell.statLabel.font = UIFont(name: "TitilliumWeb-Bold", size: (selectedFontSize / 2).rounded(.up))
            cell.numberLabel.font = UIFont(name: "TitilliumWeb-Light", size: (selectedFontSize / 2).rounded(.up))
            
            cell.backgroundColor = indexPath.row % 2 == 0 ? #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 0.5047356592) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
            
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView === creditsTableView else { return }
        
        let profile = profiles[indexPath.row]
        if let url = URL(string: profile.url) {
            displayAlert(url, domain: profile.domain)
        } else {
            print("Failed to create URL for contributor's profile")
        }
    }
    
    func displayAlert(_ url: URL, domain: String) {
        let alert = UIAlertController(title: "Do you want to continue?", message: "You're about to be redirected to a contributor's \(domain) profile.", preferredStyle: .alert)
        
        let goAction = UIAlertAction(title: "Go to website", style: .default, handler: { (_) -> Void in
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(goAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
}
