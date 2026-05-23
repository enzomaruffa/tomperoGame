import UIKit

class WaitingRoomViewController: UIViewController, Storyboarded {

    // MARK: - Storyboarded
    static var storyboardName = "WaitingRoom"
    weak var coordinator: MainCoordinator?

    // MARK: - Variables
    var hosting = false
    var closedBrowser = false

    var difficultySelected = GameDifficulty.easy

    var playersWithStatus: [PeerWithStatus] = [
        PeerWithStatus(name: "__empty__", status: .notConnected),
        PeerWithStatus(name: "__empty__", status: .notConnected),
        PeerWithStatus(name: "__empty__", status: .notConnected),
        PeerWithStatus(name: "__empty__", status: .notConnected)
    ]
    
    // MARK: - Outlets
    @IBOutlet weak var headerTitle: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var goBackImage: UIImageView!
    
    @IBOutlet weak var difficultyButton: UIButton!
    @IBOutlet weak var difficultyImage: UIImageView!
    
    @IBOutlet weak var stackViewCenterYConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var player1Image: UIImageView!
    @IBOutlet weak var player1Label: UILabel!
    @IBOutlet weak var player1InviteButton: UIButton!
    
    @IBOutlet weak var player2Image: UIImageView!
    @IBOutlet weak var player2Label: UILabel!
    @IBOutlet weak var player2InviteButton: UIButton!
    
    @IBOutlet weak var player3Image: UIImageView!
    @IBOutlet weak var player3Label: UILabel!
    @IBOutlet weak var player3InviteButton: UIButton!
    
    @IBOutlet weak var player4Image: UIImageView!
    @IBOutlet weak var player4Label: UILabel!
    @IBOutlet weak var player4InviteButton: UIButton!
    
    // MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = stackViewCenterYConstraint.setMultiplier(multiplier: hosting ? 0.95 : 1)
        updateViewConstraints()
        
        if let diffLabel = difficultyButton.titleLabel {
            diffLabel.numberOfLines = 1
            diffLabel.adjustsFontSizeToFitWidth = true
        }
        
        headerTitle.numberOfLines = 1
        headerTitle.adjustsFontSizeToFitWidth = true
        player1Label.adjustsFontSizeToFitWidth = true
        player2Label.adjustsFontSizeToFitWidth = true
        player3Label.adjustsFontSizeToFitWidth = true
        player4Label.adjustsFontSizeToFitWidth = true
        
        if hosting {
            Log.network.debug("Hosting waiting room")
            playersWithStatus = [PeerWithStatus(name: LANConnectionManager.shared.selfName, status: .connected),
                                 PeerWithStatus(name: "__empty__", status: .notConnected),
                                 PeerWithStatus(name: "__empty__", status: .notConnected),
                                 PeerWithStatus(name: "__empty__", status: .notConnected)]
            LANConnectionManager.shared.startHosting()
        } else {
            LANConnectionManager.shared.startJoining()
        }

        LANConnectionManager.shared.subscribeMatchmakingObserver(observer: self)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateDifficultyButton(difficulty: difficultySelected)
        
        player1InviteButton.isHidden = true
        player2InviteButton.isHidden = true
        player3InviteButton.isHidden = true
        player4InviteButton.isHidden = true
        
        if !hosting {
            difficultyImage.isHidden = true
            goButton.isHidden = true
            difficultyButton.isHidden = true
            goBackImage.isHidden = true
        }
        
        updatePlayers(playersWithStatus)
    }
     
    // MARK: - Buttons
    
    @IBAction func backPressed(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "waiting-back")
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func menuPressed(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "waiting-recipeMenu")
        self.coordinator?.menu()
    }
    
    @IBAction func play(_ sender: Any) {
        // Generate rules and send to other players
        EventLogger.shared.logButtonPress(buttonName: "waiting-play")

        let peers = playersWithStatus.map({ $0.name })
        let rule = GameRuleFactory.generateRule(difficulty: difficultySelected, players: peers)

        do {
            let ruleData = try JSONEncoder().encode(rule)
            LANConnectionManager.shared.sendEveryone(dataWrapper: WirePayload(object: ruleData, type: .gameRule))
        } catch {
            Log.network.debug("Failed to encode GameRule: \(error.localizedDescription)")
            return
        }

        MusicPlayer.shared.stop(.menu)

        // Start game view with necessary information
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.coordinator?.game(rule: rule, hosting: true)
        }
    }
    
    @IBAction func difficultyPressed(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "waiting-difficulty")
        
        if difficultySelected == .easy {
            difficultySelected = .medium
        } else if difficultySelected == .medium {
            difficultySelected = .hard
        } else if difficultySelected == .hard {
            difficultySelected = .easy
        }
        
        updateDifficultyButton(difficulty: difficultySelected)
    }
    
    func updateDifficultyButton(difficulty: GameDifficulty) {
        switch difficulty {
        case .easy:
            difficultyButton.setTitle("EASY", for: .normal)
        case .medium:
            difficultyButton.setTitle("MEDIUM", for: .normal)
        case .hard:
            difficultyButton.setTitle("HARD", for: .normal)
        }
    }
    
    @IBAction func player1InviteButtonPressed(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "waiting-invite")
        presentPeerPicker()
    }
    @IBAction func player2InviteButtonPressed(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "waiting-invite")
        presentPeerPicker()
    }
    @IBAction func player3InviteButtonPressed(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "waiting-invite")
        presentPeerPicker()
    }
    @IBAction func player4InviteButtonPressed(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "waiting-invite")
        presentPeerPicker()
    }

    private func presentPeerPicker() {
        let picker = PeerPickerViewController()
        picker.delegate = self
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
    
    // MARK: - Methods
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        guard let tappedImage = tapGestureRecognizer.view as? UIImageView else { return }
        imageViewOpacity(imageView: tappedImage)
    }
    
    func imageViewOpacity(imageView: UIImageView) {
        imageView.alpha = 0.2
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveLinear], animations: {imageView.alpha = 1.0
        }, completion: {(_) in
            UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveLinear], animations: {
                imageView.alpha = 0.2
            }, completion: {(_) in
                UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveLinear], animations: {
                    imageView.alpha = 1.0
                })
            })
        })
        
    }
    
    func changeImageAnimated(image: String, viewChange: UIImageView) {
        guard let currentImage = viewChange.image, let newImage = UIImage(named: image) else {
            return
        }
        let crossFade: CABasicAnimation = CABasicAnimation(keyPath: "contents")
        crossFade.duration = 0.3
        crossFade.fromValue = currentImage.cgImage
        crossFade.toValue = newImage.cgImage
        crossFade.isRemovedOnCompletion = false
        crossFade.fillMode = CAMediaTimingFillMode.forwards
        viewChange.layer.add(crossFade, forKey: "animateContents")
    }
    
    func checkGoButton(playersWithStatus: [PeerWithStatus]) {
        DispatchQueue.main.async {
            if playersWithStatus.filter({ $0.status == .connected }).count <= 1 {
                self.goButton.isEnabled = false
            } else {
                self.goButton.isEnabled = true
            }
        }
    }
    
    private func updatePlayers(_ playersWithStatus: [PeerWithStatus]) {
        checkGoButton(playersWithStatus: playersWithStatus)
        for index in 0..<playersWithStatus.count {
            // Esse loop, antes, só entrava se o usuário estivesse entnraod pela primeira vez na lista (pra não fazer animação  repetida. Como agora  não tem a animação doida, ele entra  sempre no loop
            // if playersWithStatus[index].name != oldList[index].name {
            Log.network.debug("Jogador \(index) com nome \(playersWithStatus[index].name) entrou")
            
            // Precisamos do dispatch queue pois estamos fazendo mudanças no UIKit e isso precisa do thread principal
            DispatchQueue.main.async {
                
                // Achamos o jogador, faz o chapeu dele entrar.
                // Sabemos qual chapeu pelo valor de index
                if index == 0 {
                    let hat = self.player1Image!
                    if playersWithStatus[index].status == .notConnected {
                        self.player1Label.text = ""
                        self.changeImageAnimated(image: "VREX - Vazio", viewChange: hat)
                        if self.hosting {
                            self.player1InviteButton.isHidden = false
                        }
                    } else if playersWithStatus[index].status == .connecting {
                        self.player1Label.text = "..."
                        self.changeImageAnimated(image: "VREX - redline", viewChange: hat)
                    } else {
                        self.player1Label.text = playersWithStatus[index].name
                        self.changeImageAnimated(image: "VREX - FULL", viewChange: hat)
                    }
                } else if index == 1 {
                    let hat = self.player2Image!
                    if playersWithStatus[index].status == .notConnected {
                        self.player2Label.text = ""
                        self.changeImageAnimated(image: "SW77 - Vazio", viewChange: hat)
                        if self.hosting {
                            self.player2InviteButton.isHidden = false
                        }
                    } else if playersWithStatus[index].status == .connecting {
                        self.player2Label.text = "..."
                        self.changeImageAnimated(image: "SW77 - redline", viewChange: hat)
                    } else {
                        self.player2Label.text = playersWithStatus[index].name
                        self.changeImageAnimated(image: "SW77 - FULL", viewChange: hat)
                        if self.hosting {
                            self.player2InviteButton.setTitle(.none, for: .normal)
                            self.player2InviteButton.isEnabled = false
                        }
                    }
                } else if index == 2 {
                    let hat = self.player3Image!
                    if playersWithStatus[index].status == .notConnected {
                        self.player3Label.text = ""
                        self.changeImageAnimated(image: "MORGAN - Vazio", viewChange: hat)
                        if self.hosting {
                            self.player3InviteButton.isHidden = false
                        }
                    } else if playersWithStatus[index].status == .connecting {
                        self.player3Label.text = "..."
                        self.changeImageAnimated(image: "MORGAN - redline", viewChange: hat)
                    } else {
                        self.player3Label.text = playersWithStatus[index].name
                        self.changeImageAnimated(image: "MORGAN - FULL", viewChange: hat)
                        if self.hosting {
                            self.player3InviteButton.setTitle(.none, for: .normal)
                            self.player3InviteButton.isEnabled = false
                        }
                    }
                } else if index == 3 {
                    let hat = self.player4Image!
                    if playersWithStatus[index].status == .notConnected {
                        self.player4Label.text = ""
                        self.changeImageAnimated(image: "JERRY - Vazio", viewChange: hat)
                        if self.hosting {
                            self.player4InviteButton.isHidden = false
                        }
                    } else if playersWithStatus[index].status == .connecting {
                        self.player4Label.text = "..."
                        self.changeImageAnimated(image: "JERRY - redline", viewChange: hat)
                    } else {
                        self.player4Label.text = playersWithStatus[index].name
                        self.changeImageAnimated(image: "JERRY - FULL", viewChange: hat)
                        if self.hosting {
                            self.player4InviteButton.setTitle(.none, for: .normal)
                            self.player4InviteButton.isEnabled = false
                        }
                    }
                }
            }
            
        }
    }
}

// MARK: - PeerPickerDelegate Methods
extension WaitingRoomViewController: PeerPickerDelegate {

    func peerPickerDidFinish(_ picker: PeerPickerViewController) {
        picker.dismiss(animated: true)
        closedBrowser = true
        updatePlayers(playersWithStatus)
    }

    func peerPickerDidCancel(_ picker: PeerPickerViewController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - LANMatchmakingObserver Methods
extension WaitingRoomViewController: LANMatchmakingObserver {

    func receiveGameRule(rule: GameRule) {
        // start game
        LANConnectionManager.shared.stopAdvertising()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            MusicPlayer.shared.stop(.menu)
            self.coordinator?.game(rule: rule, hosting: false)
        }
    }

    func playerListSent(playersWithStatus: [PeerWithStatus]) {
        Log.network.debug("\(playersWithStatus)")
        if self.playersWithStatus != playersWithStatus && !self.hosting {
            
            let oldList = self.playersWithStatus
            
            guard !oldList.isEmpty else {
                // rodar as animações para todos
                return
            }
            updatePlayers(playersWithStatus)
            // seta o da classe pro novo
            self.playersWithStatus = playersWithStatus
        } else {
        }
    }
    
    func playerUpdate(player: String, state: PeerConnectionState) {

        // host envia para todos a lista
        if hosting {
            // atualizo a lista do host

            let newPlayerList = self.playersWithStatus.map({ $0.copy() })

            Log.network.debug("Atualizando lista")
            Log.network.debug("Players na lista: \(newPlayerList.map({$0.name}))")
            if !newPlayerList.filter({ $0.name == player }).isEmpty {
                // ja existe, atualiza estado

                let playerWithStatus = newPlayerList.first(where: { $0.name == player })
                playerWithStatus?.status = state
            } else {
                // procura espaço vazio
                if let emptyPlayerWithStatus = newPlayerList.filter({ $0.name == "__empty__" }).first {
                    emptyPlayerWithStatus.name = player
                    emptyPlayerWithStatus.status = state
                } else if let ncPlayerWithStatus = newPlayerList.filter({ $0.status == .notConnected }).first {
                    ncPlayerWithStatus.name = player
                    ncPlayerWithStatus.status = state
                }
            }

            Log.network.debug("Enviando lista pros Peers")
            LANConnectionManager.shared.sendPeersStatus(playersWithStatus: newPlayerList)
            self.playersWithStatus = newPlayerList

            if closedBrowser {
                updatePlayers(newPlayerList)
            }
        }
    }
}
