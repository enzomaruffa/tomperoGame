import UIKit
import MultipeerConnectivity

class WaitingRoomViewController: UIViewController, Storyboarded {
    
    // MARK: - Storyboarded
    static var storyboardName = "WaitingRoom"
    weak var coordinator: MainCoordinator?
    
    // MARK: - Variables
    var hosting = false
    var animationTimer: Timer?
    var countLevel = GameDifficulty.easy
    
    var playersWithStatus: [MCPeerWithStatus] = [
        MCPeerWithStatus(peer: "__empty__", status: .notConnected),
        MCPeerWithStatus(peer: "__empty__", status: .notConnected),
        MCPeerWithStatus(peer: "__empty__", status: .notConnected),
        MCPeerWithStatus(peer: "__empty__", status: .notConnected)
    ]
    
    var playersImages: [UIImageView]!
    let singleAnimationDuration = 0.35
    
    var closedBrowser = false
    var viewOriginalTransform:CGAffineTransform!
    var zoomedAndTransformed: CGAffineTransform!
    
    // MARK: - Outlets
    @IBOutlet weak var headerTitle: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var goBackImage: UIImageView!
    
    @IBOutlet weak var level: UIButton!
    @IBOutlet weak var levelBackImage: UIImageView!
    
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
        
        if let levelLabel = level.titleLabel {
            levelLabel.numberOfLines = 1
            levelLabel.adjustsFontSizeToFitWidth = true
        }
        headerTitle.numberOfLines = 1
        headerTitle.adjustsFontSizeToFitWidth = true
        player1Label.adjustsFontSizeToFitWidth = true
        player2Label.adjustsFontSizeToFitWidth = true
        player3Label.adjustsFontSizeToFitWidth = true
        player4Label.adjustsFontSizeToFitWidth = true
        
        // Array com lista de connected players
        //MCManager.shared.mcSession?.connectedPeers
        
        if hosting {
            print(" CURRENTLY HOSTING<<")
            playersWithStatus = [MCPeerWithStatus(peer: MCManager.shared.peerID!.displayName, status: .connected),
                                 MCPeerWithStatus(peer: "__empty__", status: .notConnected),
                                 MCPeerWithStatus(peer: "__empty__", status: .notConnected),
                                 MCPeerWithStatus(peer: "__empty__", status: .notConnected)]
            //            MCManager.shared.hostSession(presentingFrom: self, delegate: self)
        } else {
            MCManager.shared.joinSession()
        }
        
        MCManager.shared.subscribeMatchmakingObserver(observer: self)
        print("STATUS DO PLAYER GREEN: ", playersWithStatus[2].status.rawValue)
        
        print("STATUS DO PLAYER ORANGE: ", playersWithStatus[3].status.rawValue)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateLevelUI(difficulty: countLevel)
        
        playersImages = [player1Image, player2Image, player3Image, player4Image]
        
        player1InviteButton.isHidden = true
        player2InviteButton.isHidden = true
        player3InviteButton.isHidden = true
        player4InviteButton.isHidden = true
        
        if !hosting {
            levelBackImage.isHidden = true
            goButton.isHidden = true
            level.isHidden = true
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
        let rule = GameRuleFactory.generateRule(difficulty: countLevel, players: peers)
        
        let ruleData = try! JSONEncoder().encode(rule)
        MCManager.shared.sendEveryone(dataWrapper: MCDataWrapper(object: ruleData, type: .gameRule))
        
        MusicPlayer.shared.stop(.menu)
        
        // Start game view with necessary information
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.coordinator?.game(rule: rule, hosting: true)
        }
    }
    
    @IBAction func levelButtom(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "waiting-difficulty")
        
        if countLevel == .easy {
            countLevel = .medium
        } else if countLevel == .medium {
            countLevel = .hard
        } else if countLevel == .hard {
            countLevel = .easy
        }
        
        updateLevelUI(difficulty: countLevel)
    }
    
    func updateLevelUI(difficulty: GameDifficulty) {
        switch difficulty {
        case .easy:
            level.setTitle("EASY", for: .normal)
        case .medium:
            level.setTitle("MEDIUM", for: .normal)
        case .hard:
            level.setTitle("HARD", for: .normal)
        }
    }
    
    @IBAction func player1InviteButtonPressed(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "waiting-invite")
        MCManager.shared.hostSession(presentingFrom: self, delegate: self)
    }
    @IBAction func player2InviteButtonPressed(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "waiting-invite")
        MCManager.shared.hostSession(presentingFrom: self, delegate: self)
    }
    @IBAction func player3InviteButtonPressed(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "waiting-invite")
        MCManager.shared.hostSession(presentingFrom: self, delegate: self)
    }
    @IBAction func player4InviteButtonPressed(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "waiting-invite")
        MCManager.shared.hostSession(presentingFrom: self, delegate: self)
    }
    
    // MARK: - Methods
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        imageViewOpacity(imageView: tappedImage)
        switch tappedImage.tag {
        case 1: print("Player 2 ", player2Image!)
        case 2: print("Player 3 ", player3Image!)
        case 3: print("Player 4 ", player4Image!)
        default: print("Player 1 ", player1Image!)
        }
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
    
    func checkGoButton(playersWithStatus: [MCPeerWithStatus]) {
        DispatchQueue.main.async {
            if playersWithStatus.filter({ $0.status == .connected }).count <= 1 {
                self.goButton.isEnabled = false
            } else {
                self.goButton.isEnabled = true
            }
        }
    }
    
    private func updatePlayers(_ playersWithStatus: [MCPeerWithStatus]) {
        checkGoButton(playersWithStatus: playersWithStatus)
        for index in 0..<playersWithStatus.count {
            // Esse loop, antes, só entrava se o usuário estivesse entnraod pela primeira vez na lista (pra não fazer animação  repetida. Como agora  não tem a animação doida, ele entra  sempre no loop
            // if playersWithStatus[index].name != oldList[index].name {
            print("[playerListSent] Jogador \(index) com nome \(playersWithStatus[index].name) entrou")
            
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
                    }
                }
            }
            
        }
    }
}

// MARK: - MCBrowserViewControllerDelegate Methods
extension WaitingRoomViewController: MCBrowserViewControllerDelegate {
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
        closedBrowser = true
//        guard playersWithStatus.count == 4 else {
//            self.navigationController?.popViewController(animated: true)
//            return
//        }
        
        updatePlayers(playersWithStatus)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
    }
    
}

// MARK: - MCManagerMatchmakingObserver Methods
extension WaitingRoomViewController: MCManagerMatchmakingObserver {
    
    func receiveGameRule(rule: GameRule) {
        // Play animation
        
        // start game
        MCManager.shared.stopAdvertiser()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.coordinator?.game(rule: rule, hosting: false)
        }
    }
    
    func playerListSent(playersWithStatus: [MCPeerWithStatus]) {
        print("[playerListSent] \(playersWithStatus)")
        if self.playersWithStatus != playersWithStatus && !self.hosting {
            
            let oldList = self.playersWithStatus
            
            guard !oldList.isEmpty else {
                print("As lista está vazia")
                // rodar as animações para todos
                return
            }
            updatePlayers(playersWithStatus)
            // seta o da classe pro novo
            self.playersWithStatus = playersWithStatus
        } else {
            print("Listas iguais")
        }
    }
    
    func playerUpdate(player: String, state: MCSessionState) {
        
        // host envia para todos a lista
        if hosting {
            // atualizo a lista do host
            
            let newPlayerList = self.playersWithStatus.map({ $0.copy() })
            
            print("\n[playerUpdate] HOSTING")
            print("[playerUpdate] Atualizando lista")
            print("[playerUpdate] Players na lista: \(newPlayerList.map({$0.name}))")
            if !newPlayerList.filter({ $0.name == player }).isEmpty {
                // ja existe, atualiza estado
                
                print(" [playerUpdate] Atualizando estado do player \(player) para \(state)")
                let playerWithStatus = newPlayerList.first(where: { $0.name == player })
                playerWithStatus?.status = state
            } else {
                // procura espaço vazio
                print(" [playerUpdate] Adicionando o player \(player)")
                if let emptyPlayerWithStatus = newPlayerList.filter({ $0.name == "__empty__" }).first {
                    print("     [playerUpdate] Achou espaço vazio!")
                    emptyPlayerWithStatus.name = player
                    emptyPlayerWithStatus.status = state
                } else if let ncPlayerWithStatus = newPlayerList.filter({ $0.status == .notConnected }).first {
                    ncPlayerWithStatus.name = player
                    ncPlayerWithStatus.status = state
                }
            }
            
            print("[playerUpdate] Enviando lista pros Peers")
            MCManager.shared.sendPeersStatus(playersWithStatus: newPlayerList)
            self.playersWithStatus = newPlayerList
            
            if closedBrowser {
                updatePlayers(newPlayerList)
            }
            
        }
    }
    
}
