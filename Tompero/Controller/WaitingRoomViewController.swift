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
    
    var playerHats: [UIImageView]!
    let singleAnimationDuration = 0.35
    
    var isZoomed = false
    var closedBrowser = false
    var viewOriginalTransform:CGAffineTransform!
    var zoomedAndTransformed: CGAffineTransform!
    
    // MARK: - Outlets
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var hatBlue: UIImageView!
    @IBOutlet weak var hatPurple: UIImageView!
    @IBOutlet weak var hatGreen: UIImageView!
    @IBOutlet weak var hatOrange: UIImageView!
    @IBOutlet weak var level: UIButton!
    @IBOutlet weak var playOutlet: UIButton!
    @IBOutlet weak var painelHost: UIImageView!
    @IBOutlet weak var levelBackImage: UIImageView!
    @IBOutlet weak var stackWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var hatBlueLBL: UILabel!
    @IBOutlet weak var hatPurpleLBL: UILabel!
    @IBOutlet weak var hatGreenLBL: UILabel!
    @IBOutlet weak var hatOrangeLBL: UILabel!
    @IBOutlet weak var inviteBlue: UIButton!
    @IBOutlet weak var invitePurple: UIButton!
    @IBOutlet weak var inviteGreen: UIButton!
    @IBOutlet weak var inviteOrange: UIButton!
    @IBOutlet weak var hatPurpleLBLCenterY: NSLayoutConstraint!
    @IBOutlet weak var hatGreenCenterY: NSLayoutConstraint!
    @IBOutlet weak var hatOrangeLBLCenterY: NSLayoutConstraint!
    @IBOutlet weak var hatBlueLBLCenterY: NSLayoutConstraint!
    // MARK: - View LifeCycle
    override func viewWillAppear(_ animated: Bool) {
        level.setTitle("EASY", for: .normal)
        playerHats = [hatBlue, hatPurple, hatGreen, hatOrange]
        
        inviteBlue.isHidden = true
        invitePurple.isHidden = true
        inviteGreen.isHidden = true
        inviteOrange.isHidden = true
        
        if hosting {
            
        } else {
            // Images
            stackWidthConstraint.setMultiplier(multiplier: 0.8)
            stackHeightConstraint.setMultiplier(multiplier: 0.8)
            stackCenterYConstraint.setMultiplier(multiplier: 1.15)
            // Names
            hatBlueLBLCenterY.setMultiplier(multiplier: 1.5)
            hatPurpleLBLCenterY.setMultiplier(multiplier: 1.5)
            hatOrangeLBLCenterY.setMultiplier(multiplier: 1.5)
            hatGreenCenterY.setMultiplier(multiplier: 1.5)
            
            levelBackImage.isHidden = true
            playOutlet.isHidden = true
            level.isHidden = true
            painelHost.isHidden = true
        }
        stackView.layoutIfNeeded()
        updatePlayers(playersWithStatus)
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
        hatBlue.tag = 0
        hatBlue.isUserInteractionEnabled = true
        hatBlue.addGestureRecognizer(tapGestureRecognizerBlue)
        hatBlue.transform = CGAffineTransform(scaleX: scaleHat, y: scaleHat)
        hatBlueLBL.text = "PLAYER 1"
        
        hatPurple.tag = 1
        hatPurple.isUserInteractionEnabled = true
        hatPurple.addGestureRecognizer(tapGestureRecognizerPurple)
        hatPurple.transform = CGAffineTransform(scaleX: scaleHat, y: scaleHat)
        hatPurpleLBL.text = "PLAYER 2"
        
        hatGreen.tag = 2
        hatGreen.isUserInteractionEnabled = true
        hatGreen.addGestureRecognizer(tapGestureRecognizerGreen)
        hatGreen.transform = CGAffineTransform(scaleX: scaleHat, y: scaleHat)
        hatGreenLBL.text = "PLAYER 3"
        
        hatOrange.tag = 3
        hatOrange.isUserInteractionEnabled = true
        hatOrange.addGestureRecognizer(tapGestureRecognizerOrange)
        hatOrange.transform = CGAffineTransform(scaleX: scaleHat, y: scaleHat)
        hatOrangeLBL.text = "PLAYER 4"
        
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
        self.navigationController?.popViewController(animated: true)
        
    }
    @IBAction func menuPressed(_ sender: Any) {
        
        let timeAnimation = 0.6
        UIView.animate(withDuration: timeAnimation, delay: 0, options: .curveEaseIn, animations: {
            self.view.transform = self.zoomedAndTransformed
        }, completion: {(_)in
            self.isZoomed = true
            self.view.transform = .identity
            let vcd = UIStoryboard(name: "MenuStoryboard", bundle: nil)
                .instantiateViewController(withIdentifier: "MenuCollectionViewController") as! MenuCollectionViewController
            vcd.vcPai = self
            vcd.modalTransitionStyle = .crossDissolve
            self.present(vcd, animated: false, completion: nil)
        })
        
    }
    
    @IBAction func play(_ sender: Any) {
        // Generate rules and send to other players
        let peers = playersWithStatus.map({ $0.name })
        let rule = GameRuleFactory.generateRule(difficulty: countLevel, players: peers)
        
        let ruleData = try! JSONEncoder().encode(rule)
        MCManager.shared.sendEveryone(dataWrapper: MCDataWrapper(object: ruleData, type: .gameRule))
        animatedSpaceshipToUP()
        
        // Start game view with necessary information
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.coordinator?.game(rule: rule, hosting: true)
        }
    }
    
    @IBAction func levelButtom(_ sender: Any) {
        
        if countLevel == .easy {
            level.setTitle("MEDIUM", for: .normal)
            countLevel = .medium
        } else if countLevel == .medium {
            level.setTitle("HARD", for: .normal)
            countLevel = .hard
        } else if countLevel == .hard {
            level.setTitle("EASY", for: .normal)
            countLevel = .easy
        }
    }
    @IBAction func inviteButtomBlue(_ sender: Any) {
        MCManager.shared.hostSession(presentingFrom: self, delegate: self)
    }
    @IBAction func inviteButtomPurple(_ sender: Any) {
        MCManager.shared.hostSession(presentingFrom: self, delegate: self)
    }
    @IBAction func inviteButtomGreen(_ sender: Any) {
        MCManager.shared.hostSession(presentingFrom: self, delegate: self)
    }
    @IBAction func inviteButtomOrange(_ sender: Any) {
        MCManager.shared.hostSession(presentingFrom: self, delegate: self)
    }
    
    // MARK: - Methods
    func zoomOut() {
        print(self)
        if self.isZoomed {
            self.view.transform = zoomedAndTransformed
            UIView.animate(withDuration: 0.7, animations: {
                self.view.transform = .identity //viewOriginalTransform
            }, completion: { (_) in
                self.view.layoutSubviews()
            })
        }
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        imageViewOpacity(imageView: tappedImage)
        if tappedImage.tag == 0 {
            
        } else if tappedImage.tag == 1 {
            print("CHAPEU SELECIONADO", hatPurple!)
            
        } else if tappedImage.tag == 2 {
            print("CHAPEU SELECIONADO", hatGreen!)
        } else if tappedImage.tag == 3 {
            print("CHAPEU SELECIONADO", hatOrange!)
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
    
    private func updatePlayers(_ playersWithStatus: [MCPeerWithStatus]) {
        for index in 0..<playersWithStatus.count {
            // Esse loop, antes, só entrava se o usuário estivesse entnraod pela primeira vez na lista (pra não fazer animação  repetida. Como agora  não tem a animação doida, ele entra  sempre no loop
            // if playersWithStatus[index].name != oldList[index].name {
            print("[playerListSent] Jogador \(index) com nome \(playersWithStatus[index].name) entrou")
            
            // Precisamos do dispatch queue pois estamos fazendo mudanças no UIKit e isso precisa do thread principal
            DispatchQueue.main.async {
                
                // Achamos o jogador, faz o chapeu dele entrar.
                // Sabemos qual chapeu pelo valor de index
                if index == 0 {
                    let hat = self.hatBlue!
                    if playersWithStatus[index].status == .notConnected {
                        self.hatBlueLBL.text = "?"
                        self.changeImageAnimated(image: "VREX - Vazio", viewChange: hat)
                        if self.hosting {
                            self.inviteBlue.isHidden = false
                        }
                    } else if playersWithStatus[index].status == .connecting {
                        self.hatBlueLBL.text = "..."
                        
                        self.changeImageAnimated(image: "VREX - redline", viewChange: hat)
                    } else {
                        self.hatBlueLBL.text = playersWithStatus[index].name
                        self.changeImageAnimated(image: "VREX - FULL", viewChange: hat)
                        
                    }
                } else if index == 1 {
                    let hat = self.hatPurple!
                    if playersWithStatus[index].status == .notConnected {
                        self.hatPurpleLBL.text = "?"
                        self.changeImageAnimated(image: "SW77 - Vazio", viewChange: hat)
                        if self.hosting {
                            self.invitePurple.isHidden = false
                        }
                    } else if playersWithStatus[index].status == .connecting {
                        self.hatPurpleLBL.text = "..."
                        self.changeImageAnimated(image: "SW77 - redline", viewChange: hat)
                    } else {
                        self.hatPurpleLBL.text = playersWithStatus[index].name
                        self.changeImageAnimated(image: "SW77 - FULL", viewChange: hat)
                    }
                } else if index == 2 {
                    let hat = self.hatGreen!
                    if playersWithStatus[index].status == .notConnected {
                        self.hatGreenLBL.text = "?"
                        self.changeImageAnimated(image: "MORGAN - Vazio", viewChange: hat)
                        if self.hosting {
                            self.inviteGreen.isHidden = false
                        }
                    } else if playersWithStatus[index].status == .connecting {
                        self.hatGreenLBL.text = "..."
                        self.changeImageAnimated(image: "MORGAN - redline", viewChange: hat)
                    } else {
                        self.hatGreenLBL.text = playersWithStatus[index].name
                        self.changeImageAnimated(image: "MORGAN - FULL", viewChange: hat)
                    }
                } else if index == 3 {
                    let hat = self.hatOrange!
                    if playersWithStatus[index].status == .notConnected {
                        self.hatOrangeLBL.text = "?"
                        self.changeImageAnimated(image: "JERRY - Vazio", viewChange: hat)
                        if self.hosting {
                            self.inviteOrange.isHidden = false
                        }
                    } else if playersWithStatus[index].status == .connecting {
                        self.hatOrangeLBL.text = "..."
                        self.changeImageAnimated(image: "JERRY - redline", viewChange: hat)
                    } else {
                        self.hatOrangeLBL.text = playersWithStatus[index].name
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
        
        self.navigationController?.popViewController(animated: true)
    }
    
}

// MARK: - MCManagerMatchmakingObserver Methods
extension WaitingRoomViewController: MCManagerMatchmakingObserver {
    
    func receiveGameRule(rule: GameRule) {
        print("Received game rule!")
        print("\(type(of: rule.possibleIngredients))")
        
        for player in rule.playerTables.keys.sorted(by: {$0 < $1}) {
            print("\(player):")
            for table in rule.playerTables[player]! {
                if table.type == .ingredient {
                    print("    \(table.type) | \(table.ingredient!)")
                } else {
                    print("    \(table.type)")
                }
            }
        }
        
        print("\nSample orders: ")
        
        for counter in 0..<3 {
            print("\nOrder \(counter): ")
            let order = rule.generateOrder()
            for ingredient in order.ingredients {
                print(type(of: ingredient))
            }
            print("Total actions to prepare: \(order.ingredients.reduce(0, {$0 + $1.numberOfActionsTilReady}))")
        }
        
        // Play animation
        
        // start game
        MCManager.shared.stopAdvertiser()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
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
