import UIKit
import MultipeerConnectivity

enum UIModalTransitionStyle : Int {
    case coverVertical = 0
    case flipHorizontal
    case crossDissolve
    case partialCurl
}

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
    
    var viewOriginalTransform:CGAffineTransform!
    
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
    
    // MARK: - View LifeCycle
    override func viewWillAppear(_ animated: Bool) {
        level.setTitle("EASY", for: .normal)
        playerHats = [hatBlue, hatPurple, hatGreen, hatOrange]
        //        setHatOrigin(hat: hatBlue, xPosition: 2000, yPosition: -1200, xScale: 0.25, yScale: 0.25)
        //        setHatOrigin(hat: hatPurple, xPosition: -1000, yPosition: +1200, xScale: 0.25, yScale: 0.25)
        //        setHatOrigin(hat: hatGreen, xPosition: 3000, yPosition: 0, xScale: 0.25, yScale: 0.25)
        //        setHatOrigin(hat: hatOrange, xPosition: -4000, yPosition: -1200, xScale: 0.25, yScale: 0.25)
        
        level.isHidden = false
        if hosting {
            //            stackWidthConstraint.setMultiplier(multiplier: 0.8)
            //            stackHeightConstraint.setMultiplier(multiplier: 0.8)
            //   stackWidthConstraint.constant = 1.0
            //            stackView.frame.size.height = self.view.frame.size.height
        } else {
            stackWidthConstraint.setMultiplier(multiplier: 0.8)
            stackHeightConstraint.setMultiplier(multiplier: 0.8)
            stackCenterYConstraint.setMultiplier(multiplier: 1.0)
            
            //stackHeightConstraint.multiplier = 2.0
            stackView.frame.size.height = self.view.frame.size.height
            stackView.frame.size.width = self.view.frame.size.width
            stackView.frame.origin = self.view.frame.origin
            
            levelBackImage.isHidden = true
            playOutlet.isHidden = true
            level.isHidden = true
            painelHost.isHidden = true
        }
        stackView.layoutIfNeeded()
        
    }
    
    func zoomOut() {
        if isZoomed {
            UIView.animate(withDuration: 0.7, animations: {
                self.view.transform = self.viewOriginalTransform
            }, completion: { (_) in
                self.view.layoutSubviews()
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            MCManager.shared.hostSession(presentingFrom: self, delegate: self)
        } else {
            MCManager.shared.joinSession()
        }
        
        MCManager.shared.subscribeMatchmakingObserver(observer: self)
    }
    
    // MARK: - ActionsButtons
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        
    }
    @IBAction func menuPressed(_ sender: Any) {
        
        viewOriginalTransform = self.view.transform
        let scaleX = (view.frame.width/menuButton.frame.width)*1.1
        let scaleY = (view.frame.height/menuButton.frame.height)*1.1
        
        let scaledTransform = viewOriginalTransform.scaledBy(x: scaleX, y: scaleY)
        let scaledAndTranslatedTransform = scaledTransform.translatedBy(x: (-2400)/scaleX, y: 1225/scaleY)
        print("scale \(scaleX) \(scaleY)")
        isZoomed = true
        
        UIView.animate(withDuration: 1, animations: {
            self.view.transform = scaledAndTranslatedTransform
            
            print("SCALE X", scaleX)
            print("SCALE Y", scaleY)
            let vcd = UIStoryboard(name: "MenuStoryboard", bundle: nil)
                .instantiateViewController(withIdentifier: "MenuCollectionViewController") as! MenuCollectionViewController
            //vcd.modalPresentationStyle = .overCurrentContext
            vcd.vcPai = self
            vcd.modalTransitionStyle = .crossDissolve
            self.present(vcd, animated: true, completion: nil)
        })
        
        /*let vcd = UIStoryboard(name: "MenuStoryboard", bundle: nil).instantiateViewController(withIdentifier: "MenuCollectionViewController") as! MenuCollectionViewController
         vcd.modalPresentationStyle = .popover
         
         //let vcd = storyboard!.instantiateViewController(withIdentifier: "MenuCollectionViewController") as! MenuCollectionViewController
         //vcd.modalTransitionStyle = .coverVertical
         self.present(vcd, animated: false, completion: nil)*/
        //coordinator?.menu()
    }
    
    @IBAction func play(_ sender: Any) {
        // Generate rules and send to other players
        let peers = playersWithStatus.map({ $0.name })
        let rule = GameRuleFactory.generateRule(difficulty: .easy, players: peers)
        let ruleData = try! JSONEncoder().encode(rule)
        MCManager.shared.sendEveryone(dataWrapper: MCDataWrapper(object: ruleData, type: .gameRule))
        
        var counter = 0
        if animationTimer == nil {
            animationTimer = Timer.scheduledTimer(withTimeInterval: singleAnimationDuration, repeats: true, block: { (_) in
                self.playerHats.forEach({ self.playAnimatedSpaceshipLeftAndRight(hat: $0) })
                counter += 1
                
                if (self.singleAnimationDuration) * Double(counter) > 3.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.animationTimer?.invalidate()
                        self.playerHats.forEach({ $0.transform = CGAffineTransform(rotationAngle: CGFloat(0)) })
                        self.playerHats.forEach({ self.animatedSpaceshipToUP(hat: $0) })
                        self.animationTimer = nil
                    }
                }
            })
            animationTimer!.fire()
        }
        
        // Start game view with necessary information
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            print("before segue peers are \(MCManager.shared.connectedPeers)")
            print("coordinating game opening with rule \(rule)")
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
    
    // MARK: - Methods
    func setHatOrigin(hat: UIImageView, xPosition: CGFloat, yPosition: CGFloat, xScale: CGFloat, yScale: CGFloat) {
        let originalTransform = CGAffineTransform.identity
        let scaledTransform = originalTransform.scaledBy(x: xScale, y: yScale)
        let scaledAndTranslatedTransform  = scaledTransform.translatedBy(x: xPosition, y: yPosition)
        hat.transform = scaledAndTranslatedTransform
    }
    
    @objc fileprivate func handleTapAnimations(hat: UIImageView) {
        UIView.animate(withDuration: 5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            hat.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            hat.transform = CGAffineTransform(translationX: 0, y: 0)
            
        })
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
    
    func animatedSpaceshipToUP(hat: UIImageView) {
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
            hat.transform = CGAffineTransform(translationX: 0, y: -400)
            print("SUBIU")
        })
    }
    
    func playAnimatedSpaceshipLeftAndRight(hat: UIImageView) {
        let hatAngle = atan2f(Float(hat.transform.b), Float(hat.transform.a))
        if hatAngle < 0 {
            UIView.animate(withDuration: self.singleAnimationDuration,
                           delay: 0.1,
                           usingSpringWithDamping: 0.4,
                           initialSpringVelocity: 0.5,
                           options: [.curveEaseInOut],
                           animations: {
                            hat.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/(1 * 14)))
            })
        } else {
            UIView.animate(withDuration: self.singleAnimationDuration,
                           delay: 0.1,
                           usingSpringWithDamping: 0.4,
                           initialSpringVelocity: 0.5,
                           options: [.curveEaseInOut],
                           animations: {
                            hat.transform = CGAffineTransform(rotationAngle: CGFloat(-1 * Double.pi/14))
            })
        }
    }
    
}

// MARK: - MCBrowserViewControllerDelegate Methods
extension WaitingRoomViewController: MCBrowserViewControllerDelegate {
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
        
        //        guard playersWithStatus.count == 4 else {
        //            self.navigationController?.popViewController(animated: true)
        //            return
        //        }
        
        for index in 0..<self.playersWithStatus.count {
            print("Playing animation with index \(index)")
            print("\(self.playerHats[index].transform)")
            // self.setHatOrigin(hat: self.playerHats[index], xPosition: 0, yPosition: 0, xScale: 0.5, yScale: 0.5)
            print("\(self.playerHats[index].transform)")
        }
        
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
            for index in 0..<playersWithStatus.count {
                // Esse loop, antes, só entrava se o usuário estivesse entnraod pela primeira vez na lista (pra não fazer animação  repetida. Como agora  não tem a animação doida, ele entra  sempre no loop
                // if playersWithStatus[index].name != oldList[index].name {
                print("[playerListSent] Jogador \(index) com nome \(playersWithStatus[index].name) entrou")
                
                // Precisamos do dispatch queue pois estamos fazendo mudanças no UIKit e isso precisa do thread principal
                DispatchQueue.main.async {
                    
                    // Achamos o jogador, faz o chapeu dele entrar.
                    // Sabemos qual chapeu pelo valor de index
                    if index == 0 {
                        if playersWithStatus[index].status == .notConnected {
                            self.hatBlueLBL.text = "?"
                            self.hatBlue.image = UIImage(named: "VREX - Vazio")
                        } else if playersWithStatus[index].status == .connecting {
                            self.hatBlueLBL.text = "..."
                            self.hatBlue.image = UIImage(named: "VREX - redline")
                        } else {
                            self.hatBlueLBL.text = playersWithStatus[index].name
                            self.hatBlue.image = UIImage(named: "VREX - FULL")
                        }
                    } else if index == 1 {
                        if playersWithStatus[index].status == .notConnected {
                            self.hatPurpleLBL.text = "?"
                            self.hatPurple.image = UIImage(named: "SW77 - Vazio")
                        } else if playersWithStatus[index].status == .connecting {
                            self.hatPurpleLBL.text = "..."
                            self.hatPurple.image = UIImage(named: "SW77 - redline")
                        } else {
                            self.hatPurpleLBL.text = playersWithStatus[index].name
                            self.hatPurple.image = UIImage(named: "SW77 - FULL")
                        }
                    } else if index == 2 {
                        if playersWithStatus[index].status == .notConnected {
                            self.hatGreenLBL.text = "?"
                            self.hatGreen.image = UIImage(named: "MORGAN - Vazio")
                        } else if playersWithStatus[index].status == .connecting {
                            self.hatGreenLBL.text = "..."
                            self.hatGreen.image = UIImage(named: "MORGAN - redline")
                        } else {
                            self.hatGreenLBL.text = playersWithStatus[index].name
                            self.hatGreen.image = UIImage(named: "MORGAN - FULL")
                        }
                    } else if index == 3 {
                        if playersWithStatus[index].status == .notConnected {
                            self.hatOrangeLBL.text = "?"
                            self.hatOrange.image = UIImage(named: "JERRY - Vazio")
                        } else if playersWithStatus[index].status == .connecting {
                            self.hatOrangeLBL.text = "..."
                            self.hatOrange.image = UIImage(named: "JERRY - redline")
                        } else {
                            self.hatOrangeLBL.text = playersWithStatus[index].name
                            self.hatOrange.image = UIImage(named: "JERRY - FULL")
                        }
                    }
                }
                
            }
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
        }
    }
    
}
