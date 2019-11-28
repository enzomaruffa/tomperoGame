import UIKit
import MultipeerConnectivity

class WaitingRoomViewController: UIViewController, Storyboarded {
    
    // MARK: - Storyboarded
    static var storyboardName = "WaitingRoom"
    weak var coordinator: MainCoordinator?
    
    // MARK: - Variables
    var hosting = false
     
    var playersWithStatus: [MCPeerWithStatus] = [MCPeerWithStatus(peer: "__empty__", status: .notConnected),
        MCPeerWithStatus(peer: "__empty__", status: .notConnected),
        MCPeerWithStatus(peer: "__empty__", status: .notConnected),
        MCPeerWithStatus(peer: "__empty__", status: .notConnected)]
        
    // MARK: - Outlets
    @IBOutlet weak var topText: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var hatBlue: UIImageView!
    @IBOutlet weak var hatPurple: UIImageView!
    @IBOutlet weak var hatGreen: UIImageView!
    @IBOutlet weak var hatOrange: UIImageView!
    @IBOutlet weak var inviteLBL: UILabel!
    
    // MARK: - View LifeCycle
    override func viewWillAppear(_ animated: Bool) {
        caracterOrigin(caracater: hatBlue, xPosition: 2000, yPosition: -1200, xScale: 0.25, yScale: 0.25)
        caracterOrigin(caracater: hatPurple, xPosition: -1000, yPosition: +1200, xScale: 0.25, yScale: 0.25)
        caracterOrigin(caracater: hatGreen, xPosition: 3000, yPosition: 0, xScale: 0.25, yScale: 0.25)
        caracterOrigin(caracater: hatOrange, xPosition: -4000, yPosition: -1200, xScale: 0.25, yScale: 0.25)
        
        stackView.isHidden = true
        topText.isHidden = true
        inviteLBL.text = "WAITING FOR INVITE"
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Array com lista de connected players
        //MCManager.shared.mcSession?.connectedPeers
        //view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapAnimations)))
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
        coordinator?.menu()
    }
    
    
    // MARK: - Methods
    func caracterOrigin(caracater: UIImageView, xPosition: CGFloat, yPosition: CGFloat, xScale: CGFloat, yScale: CGFloat) {
        let originalTransform = caracater.transform
        let scaledTransform = originalTransform.scaledBy(x: xScale, y: yScale)
        let scaledAndTranslatedTransform  = scaledTransform.translatedBy(x: xPosition, y: yPosition)
        caracater.transform = scaledAndTranslatedTransform
    }
    
    @objc fileprivate func handleTapAnimations(hat: UIImageView) {
        UIView.animate(withDuration: 5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            
            hat.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            hat.transform = CGAffineTransform(translationX: 0, y: 0)
            
        }) { (_) in
            
        }
    }
    
}

// MARK: - MCBrowserViewControllerDelegate Methods
extension WaitingRoomViewController: MCBrowserViewControllerDelegate {
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
    }
    
}

// MARK: - MCManagerMatchmakingObserver Methods
extension WaitingRoomViewController: MCManagerMatchmakingObserver {
    
    func receiveTableDistribution(playerTables: [PlayerTable]) {
        
    }
    
    func playerListSent(playersWithStatus: [MCPeerWithStatus]) {
        print("[playerListSent] \(playersWithStatus)")
        if self.playersWithStatus != playersWithStatus {
            
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                            if index == 0 {
                                self.stackView.isHidden = false
                                self.topText.isHidden = false
                                self.inviteLBL.isHidden = true
                                self.handleTapAnimations(hat: self.hatBlue)
                            } else if index == 1 {
                                self.handleTapAnimations(hat: self.hatPurple)
                            } else if index == 2 {
                                self.handleTapAnimations(hat: self.hatPurple)
                            } else if index == 3 {
                                self.handleTapAnimations(hat: self.hatPurple)
                            }
                        }
                    }
                }
            }
            
            // Mudança de estado
            for index in 0..<playersWithStatus.count {
                if playersWithStatus[index].status != oldList[index].status {
                    print("[playerListSent] Jogador \(index) com nome \(playersWithStatus[index].name) mudou de estado")
                    // Achamos o jogador, faz o chapeu dele mudar.
                    // Sabemos qual chapeu pelo valor de i
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
            
            print("\n\n[playerUpdate] HOSTING")
            print("[playerUpdate] Atualizando lista")
            print("[playerUpdate] Players na lista: \(newPlayerList.map({$0.name}))")
            if !newPlayerList.filter({ $0.name == player }).isEmpty {
                // ja existe, atualiza estado

                print("[playerUpdate] Atualizando estado do player \(player) para \(state)")
                let playerWithStatus = newPlayerList.first(where: { $0.name == player })
                playerWithStatus?.status = state
            } else {
                // procura espaço vazio
                print("[playerUpdate] Adicionando o player \(player)")
                if let emptyPlayerWithStatus = newPlayerList.filter({ $0.name == "__empty__" }).first {
                    print("[playerUpdate] Achou espaço vazio!")
                    emptyPlayerWithStatus.name = player
                    emptyPlayerWithStatus.status = state
                } else if let ncPlayerWithStatus = newPlayerList.filter({ $0.status == .notConnected }).first {
                    ncPlayerWithStatus.name = player
                    ncPlayerWithStatus.status = state
                }
            }
            
            MCManager.shared.sendPeersStatus(playersWithStatus: newPlayerList)
            print("Calling player list sent")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.playerListSent(playersWithStatus: newPlayerList)
            }
        }
    }
    
}
