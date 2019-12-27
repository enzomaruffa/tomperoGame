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
    
    var playersWithStatus: [MCPeerWithStatus] = [MCPeerWithStatus(peer: "__empty__", status: .notConnected),
                                                 MCPeerWithStatus(peer: "__empty__", status: .notConnected),
                                                 MCPeerWithStatus(peer: "__empty__", status: .notConnected),
                                                 MCPeerWithStatus(peer: "__empty__", status: .notConnected)]
    
    var playersImages: [UIImageView]!
    let singleAnimationDuration = 0.35
    
    var isZoomed = false
    var closedBrowser = false
    var viewOriginalTransform:CGAffineTransform!
    var zoomedAndTransformed: CGAffineTransform!
    
    // MARK: - Outlets
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    
    @IBOutlet weak var painelHost: UIImageView!
    
    @IBOutlet weak var level: UIButton!
    @IBOutlet weak var levelBackImage: UIImageView!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet var stackWidthConstraint: NSLayoutConstraint!
    @IBOutlet var stackHeightConstraint: NSLayoutConstraint!
    @IBOutlet var stackCenterYConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var player1Image: UIImageView!
    @IBOutlet weak var player1Label: UILabel!
    @IBOutlet weak var player1InviteButton: UIButton!
    @IBOutlet var player1LabelCenterYConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var player2Image: UIImageView!
    @IBOutlet weak var player2Label: UILabel!
    @IBOutlet weak var player2InviteButton: UIButton!
    @IBOutlet var player2LabelCenterYConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var player3Image: UIImageView!
    @IBOutlet weak var player3Label: UILabel!
    @IBOutlet weak var player3InviteButton: UIButton!
    @IBOutlet var player3LabelCenterYConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var player4Image: UIImageView!
    @IBOutlet weak var player4Label: UILabel!
    @IBOutlet weak var player4InviteButton: UIButton!
    @IBOutlet var player4LabelCenterYConstraint: NSLayoutConstraint!
    
    // MARK: - View LifeCycle
    override func viewWillAppear(_ animated: Bool) {
        updateLevelUI(difficulty: countLevel)
        
        playersImages = [player1Image, player2Image, player3Image, player4Image]
        
        player1InviteButton.isHidden = true
        player2InviteButton.isHidden = true
        player3InviteButton.isHidden = true
        player4InviteButton.isHidden = true
        
        if !hosting {
            // Images
            stackWidthConstraint.setMultiplier(multiplier: 0.8)
            stackHeightConstraint.setMultiplier(multiplier: 0.8)
            stackCenterYConstraint.setMultiplier(multiplier: 1.15)
            // Names
            player1LabelCenterYConstraint.setMultiplier(multiplier: 1.5)
            player2LabelCenterYConstraint.setMultiplier(multiplier: 1.5)
            player4LabelCenterYConstraint.setMultiplier(multiplier: 1.5)
            player3LabelCenterYConstraint.setMultiplier(multiplier: 1.5)
            
            levelBackImage.isHidden = true
            goButton.isHidden = true
            level.isHidden = true
            painelHost.isHidden = true
        }
        
        stackView.layoutIfNeeded()
        updatePlayers(playersWithStatus)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isZoomed {
            zoomOut()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ZOOM do menu
        let viewTransform = self.view.transform
        let scaleX = (view.frame.width/menuButton.frame.width)
        let scaleY = (view.frame.height/menuButton.frame.height)
        let translatedTransform = viewTransform.scaledBy(x: scaleX, y: scaleY)
        let translatedAndScaledTransform = translatedTransform.translatedBy(x: (-menuButton.frame.midX + self.view.frame.midX), y: -menuButton.frame.midY + self.view.frame.midY)
        self.zoomedAndTransformed = translatedAndScaledTransform
        
        let tapGestureRecognizerBlue = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        let tapGestureRecognizerPurple = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        let tapGestureRecognizerGreen = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        let tapGestureRecognizerOrange = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        
        let scaleHat = CGFloat(1.1)
        player1Image.tag = 0
        player1Image.isUserInteractionEnabled = true
        player1Image.addGestureRecognizer(tapGestureRecognizerBlue)
        player1Image.transform = CGAffineTransform(scaleX: scaleHat, y: scaleHat)
        player1Label.text = "PLAYER 1"
        
        player2Image.tag = 1
        player2Image.isUserInteractionEnabled = true
        player2Image.addGestureRecognizer(tapGestureRecognizerPurple)
        player2Image.transform = CGAffineTransform(scaleX: scaleHat, y: scaleHat)
        player2Label.text = "PLAYER 2"
        
        player3Image.tag = 2
        player3Image.isUserInteractionEnabled = true
        player3Image.addGestureRecognizer(tapGestureRecognizerGreen)
        player3Image.transform = CGAffineTransform(scaleX: scaleHat, y: scaleHat)
        player3Label.text = "PLAYER 3"
        
        player4Image.tag = 3
        player4Image.isUserInteractionEnabled = true
        player4Image.addGestureRecognizer(tapGestureRecognizerOrange)
        player4Image.transform = CGAffineTransform(scaleX: scaleHat, y: scaleHat)
        player4Label.text = "PLAYER 4"
        
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
    
    // MARK: - ActionsButtons
    @IBAction func backPressed(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "waiting-back")
        self.navigationController?.popViewController(animated: true)
        
    }
    @IBAction func menuPressed(_ sender: Any) {
        EventLogger.shared.logButtonPress(buttonName: "waiting-recipeMenu")
        
        let timeAnimation = 0.6
        UIView.animate(withDuration: timeAnimation, delay: 0, options: .curveEaseIn, animations: {
            self.view.transform = self.zoomedAndTransformed
        }, completion: {(_)in
            self.isZoomed = true
            self.view.transform = .identity
            self.coordinator?.menu()
        })
        
    }
    
    @IBAction func play(_ sender: Any) {
        // Generate rules and send to other players
        EventLogger.shared.logButtonPress(buttonName: "waiting-play")
        
        let peers = playersWithStatus.map({ $0.name })
        let rule = GameRuleFactory.generateRule(difficulty: countLevel, players: peers)
        
        let ruleData = try! JSONEncoder().encode(rule)
        MCManager.shared.sendEveryone(dataWrapper: MCDataWrapper(object: ruleData, type: .gameRule))
        animatedSpaceshipToUP()
        
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
        default:
            level.setTitle("EASY", for: .normal)
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
    func zoomOut() {
        print(self)
        if self.isZoomed {
            self.view.transform = zoomedAndTransformed
            UIView.animate(withDuration: 0.3, animations: {
                self.view.transform = .identity //viewOriginalTransform
            }, completion: { (_) in
                self.view.layoutSubviews()
            })
            self.isZoomed = false
        }
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        imageViewOpacity(imageView: tappedImage)
        if tappedImage.tag == 0 {
            
        } else if tappedImage.tag == 1 {
            print("CHAPEU SELECIONADO", player2Image!)
            
        } else if tappedImage.tag == 2 {
            print("CHAPEU SELECIONADO", player3Image!)
        } else if tappedImage.tag == 3 {
            print("CHAPEU SELECIONADO", player4Image!)
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
    
    func animatedSpaceshipToUP() {
        let positionFinal = ((painelHost.frame.size.height)/2) * (917/1117)
        print(positionFinal)
        let originalTransform = CGAffineTransform.identity
        let translatedTransform = originalTransform.translatedBy(x: (0), y: positionFinal)
        let scaledTransformAndTransform = translatedTransform.scaledBy(x: 0.001, y: 0.001)
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
            self.stackView.transform = scaledTransformAndTransform
        })
    }
    
//    func playAnimatedSpaceshipLeftAndRight() {
//        let hats = [hatBlue, hatPurple, hatGreen, hatOrange]
//        hats.forEach { (hat) in
//            let hatAngle = atan2f(Float(hat!.transform.b), Float(hat!.transform.a))
//            if hatAngle < 0 {
//                UIView.animate(withDuration: self.singleAnimationDuration, delay: 0.1, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.5, options: [.curveEaseInOut], animations: {
//                    hat!.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/(1 * 14)))
//                })
//            } else {
//                UIView.animate(withDuration: self.singleAnimationDuration, delay: 0.1, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.5, options: [.curveEaseInOut], animations: {
//                    hat!.transform = CGAffineTransform(rotationAngle: CGFloat(-1 * Double.pi/14))
//                })
//            }
//        }
//    }
    
    func checkGoButton(playersWithStatus: [MCPeerWithStatus]) {
        DispatchQueue.main.async {
            if playersWithStatus.filter({ $0.status == .connected }).count <= 1 {
                self.goButton.isEnabled = false
                self.goButton.imageView?.image = UIImage(named: "go_disabled")
            } else {
                self.goButton.isEnabled = true
                self.goButton.imageView?.image = UIImage(named: "go_")
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
