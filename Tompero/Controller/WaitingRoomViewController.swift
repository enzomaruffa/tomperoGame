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
    var countLevel = 0
    
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
    @IBOutlet weak var inviteLBL: UILabel!
    @IBOutlet weak var level: UIButton!
    @IBOutlet weak var playOutlet: UIButton!
    @IBOutlet weak var levelLBL: UILabel!
    
    // MARK: - View LifeCycle
    override func viewWillAppear(_ animated: Bool) {
        level.setTitle("EASY", for: .normal)
        playerHats = [hatBlue, hatPurple, hatGreen, hatOrange]
        setHatOrigin(hat: hatBlue, xPosition: 2000, yPosition: -1200, xScale: 0.25, yScale: 0.25)
        setHatOrigin(hat: hatPurple, xPosition: -1000, yPosition: +1200, xScale: 0.25, yScale: 0.25)
        setHatOrigin(hat: hatGreen, xPosition: 3000, yPosition: 0, xScale: 0.25, yScale: 0.25)
        setHatOrigin(hat: hatOrange, xPosition: -4000, yPosition: -1200, xScale: 0.25, yScale: 0.25)
        
        //        caracterOrigin(caracater: hatPurple, xPosition: 0, yPosition: 0, xScale: 0.5, yScale: 0.5)
        //        caracterOrigin(caracater: hatGreen, xPosition: 0, yPosition: 0, xScale: 0.5, yScale: 0.5)
        //        caracterOrigin(caracater: hatOrange, xPosition: 0, yPosition: 0, xScale: 0.5, yScale: 0.5)
        
        //stackView.isHidden = false
        inviteLBL.text = "WAITING FOR INVITE"
        inviteLBL.isHidden = true
        level.isHidden = false
        if hosting {
            level.isHidden = false
            self.handleTapAnimations(hat: self.hatBlue)
            self.handleTapAnimations(hat: self.hatPurple)
            self.handleTapAnimations(hat: self.hatOrange)
            self.handleTapAnimations(hat: self.hatGreen)
        } else {
            level.isHidden = false
            playOutlet.isHidden = true
        }
    }
    func zoomOut() {
        if isZoomed{
            UIView.animate(withDuration: 0.7, animations: {
                self.view.transform = self.viewOriginalTransform
                
            },completion:  { (_) in
                self.view.layoutSubviews()
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Array com lista de connected players
        //MCManager.shared.mcSession?.connectedPeers
        //view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapAnimations)))
        if hosting {
            self.level.isHidden = false
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
        let scaledAndTranslatedTransform = scaledTransform.translatedBy(x: (-2852)/scaleX, y: 888/scaleY)
        print("scale \(scaleX) \(scaleY)")
        isZoomed = true
        UIView.animate(withDuration: 0.7, animations: {
          self.view.transform = scaledAndTranslatedTransform
            
        },completion:  { (_) in
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
    }
    
    @IBAction func levelButtom(_ sender: Any) {
        if countLevel == 0 {
            level.setTitle("MEDIUM", for: .normal)
            countLevel = 1
        } else if countLevel == 1 {
            level.setTitle("HARD", for: .normal)
            countLevel = 2
        } else if countLevel == 2 {
            level.setTitle("EASY", for: .normal)
            countLevel = 0
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
    
    func animatedSpaceshipToUP(hat: UIImageView) {
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
            hat.transform = CGAffineTransform(translationX: 0, y: -400)
            print("SUBIU")
        })
    }
    
    func playAnimatedSpaceshipLeftAndRight(hat: UIImageView) {
        let hatAngle = atan2f(Float(hat.transform.b), Float(hat.transform.a))
        if hatAngle < 0 {
            UIView.animate(withDuration: self.singleAnimationDuration, delay: 0.1, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.5, options: [.curveEaseInOut], animations: {
                hat.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/(1 * 14)))
            })
        } else {
            UIView.animate(withDuration: self.singleAnimationDuration, delay: 0.1, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.5, options: [.curveEaseInOut], animations: {
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
        
        self.stackView.isHidden = false
        self.inviteLBL.isHidden = true
        
        for index in 0..<self.playersWithStatus.count {
            print("Playing animation with index \(index)")
            print("\(self.playerHats[index].transform)")
            self.setHatOrigin(hat: self.playerHats[index], xPosition: 0, yPosition: 0, xScale: 0.5, yScale: 0.5)
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
    
    func playerListSent(playersWithStatus: [MCPeerWithStatus]) {
        print("[playerListSent] \(playersWithStatus)")
        if self.playersWithStatus != playersWithStatus && !self.hosting {
            
            let oldList = self.playersWithStatus
            
            guard !oldList.isEmpty else {
                print("As lista está vazia")
                // rodar as animações para todos
                return
            }
            //verifica se o nome mudou pra considerar jogador entrando na sala
            if playersWithStatus.map({$0.name}).sorted() != oldList.map({$0.name}).sorted() {
                for index in 0..<playersWithStatus.count {
                    if playersWithStatus[index].name != oldList[index].name {
                        print("[playerListSent] Jogador \(index) com nome \(playersWithStatus[index].name) entrou")
                        // Achamos o jogador, faz o chapeu dele entrar.
                        // Sabemos qual chapeu pelo valor de index
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if index == 0 {
                                self.stackView.isHidden = false
                                self.inviteLBL.isHidden = true
                                self.handleTapAnimations(hat: self.hatBlue)
                            } else if index == 1 {
                                self.handleTapAnimations(hat: self.hatPurple)
                            } else if index == 2 {
                                self.handleTapAnimations(hat: self.hatOrange)
                            } else if index == 3 {
                                self.handleTapAnimations(hat: self.hatGreen)
                            }
                        }
                    }
                }
            }
            
//            // Mudança de estado
//            for index in 0..<playersWithStatus.count {
//                if playersWithStatus[index].status != oldList[index].status {
//                    print("[playerListSent] Jogador \(index) com nome \(playersWithStatus[index].name) mudou de estado")
//                    // Achamos o jogador, faz o chapeu dele mudar.
//                    // Sabemos qual chapeu pelo valor de i
//                }
//            }
            
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
        }
    }
    
}
