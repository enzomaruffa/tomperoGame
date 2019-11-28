import UIKit
import MultipeerConnectivity

class WaitingRoomViewController: UIViewController, Storyboarded {
    
    // MARK: - Storyboarded
    static var storyboardName = "WaitingRoom"
    weak var coordinator: MainCoordinator?
    
    // MARK: - Variables
    var currentPlayers: [String] = []
    var hosting = false
    var playersWithStatus: [MCPeerWithStatus] = []
    
    // MARK: - Outlets
    @IBOutlet weak var topText: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var hatBlue: UIImageView!
    @IBOutlet weak var hatPurple: UIImageView!
    @IBOutlet weak var hatGreen: UIImageView!
    @IBOutlet weak var hatOrange: UIImageView!
    
    // MARK: - ActionsButtons
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        
    }
    @IBAction func menuPressed(_ sender: Any) {
        coordinator?.menu()
    }
    
    // MARK: - View LifeCycle
    override func viewWillAppear(_ animated: Bool) {
        caracterOrigin(caracater: hatBlue, xPosition: 2000, yPosition: -1200, xScale: 0.25, yScale: 0.25)
        caracterOrigin(caracater: hatPurple, xPosition: -1000, yPosition: +1200, xScale: 0.25, yScale: 0.25)
        caracterOrigin(caracater: hatGreen, xPosition: 3000, yPosition: 0, xScale: 0.25, yScale: 0.25)
        caracterOrigin(caracater: hatOrange, xPosition: -4000, yPosition: -1200, xScale: 0.25, yScale: 0.25)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.handleTapAnimations(hat: self.hatPurple)
            self.handleTapAnimations(hat: self.hatBlue)
            self.handleTapAnimations(hat: self.hatOrange)
            self.handleTapAnimations(hat: self.hatGreen)
        }
        if currentPlayers.count > 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.handleTapAnimations(hat: self.hatBlue)
            }
        } else if currentPlayers.count > 2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.handleTapAnimations(hat: self.hatOrange)
            }
        } else if currentPlayers.count > 3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.handleTapAnimations(hat: self.hatGreen)
                
            }
        }
    }
    
    func caracterOrigin(caracater: UIImageView, xPosition: CGFloat, yPosition: CGFloat, xScale: CGFloat, yScale: CGFloat) {
        let originalTransform = caracater.transform
        let scaledTransform = originalTransform.scaledBy(x: xScale, y: yScale)
        let scaledAndTranslatedTransform  = scaledTransform.translatedBy(x: xPosition, y: yPosition)
        caracater.transform = scaledAndTranslatedTransform
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentPlayers.append("Akira")
        //view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapAnimations)))
        if hosting {
            playersWithStatus.append(MCPeerWithStatus(peer: MCManager.shared.peerID!.displayName, status: .connected))
            playersWithStatus.append(MCPeerWithStatus(peer: "__empty__", status: .notConnected))
            playersWithStatus.append(MCPeerWithStatus(peer: "__empty__", status: .notConnected))
            playersWithStatus.append(MCPeerWithStatus(peer: "__empty__", status: .notConnected))
            MCManager.shared.hostSession()
        } else {
            MCManager.shared.joinSession(presentingFrom: self, delegate: self)
        }
        
        MCManager.shared.subscribeMatchmakingObserver(observer: self)
    }
    
    @objc fileprivate func handleTapAnimations(hat: UIImageView) {
        UIView.animate(withDuration: 5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            
            hat.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            hat.transform = CGAffineTransform(translationX: 0, y: 0)
            
        }) { (_) in
            
        }
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
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
    
    func playerListSent(playersWithStatus: [MCPeerWithStatus]) {
        print("\(playersWithStatus)")
        if self.playersWithStatus != playersWithStatus {
            self.playersWithStatus = playersWithStatus
        }
    }
    
    func playerUpdate(player: String, state: MCSessionState) {
        // fazer lógica de atualizar / controlar jogadores
        print("\(player) | \(state.rawValue)")
        if MCSessionState.connected == state {
            currentPlayers.append(player)
            print("DSAUDNAUSDJASUDNJASDNA")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.handleTapAnimations(hat: self.hatBlue)
                
            }
            
        } else if MCSessionState.notConnected == state {
            currentPlayers.removeAll(where: {$0 == player})
            // roda animação de sumir
            
        }
        
        // Consigo atualizar chapeu desse player e conultar o state o que aconoteceu
        if hosting {
            MCManager.shared.sendPeersStatus(playersWithStatus: playersWithStatus)
        }
    }
    
}
