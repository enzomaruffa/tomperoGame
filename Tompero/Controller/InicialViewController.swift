import UIKit
import MultipeerConnectivity
import GameKit

class InicialViewController: UIViewController, Storyboarded, GKGameCenterControllerDelegate {
    
    // MARK: - Storyboarded
    static var storyboardName = "Main"
    
    // MARK: - Variables
    weak var coordinator: MainCoordinator?
    let databaseManager: DatabaseManager = CloudKitManager.shared
    let logger: ConsoleDebugLogger = ConsoleDebugLogger.shared
    var location = CGPoint(x: 0, y: 0)
    var animationTimer: Timer?
    weak var shapeLayer: CAShapeLayer?
    
    // MARK: - Game Center
    var isGameCenterEnabled: Bool! // check if Game Center enabled
    var defaultLeaderboard = "" // check default leaderboard ID
    
    // MARK: - Outlets
    @IBOutlet weak var join: UIImageView!
    @IBOutlet weak var host: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var textBox: UIImageView!
    @IBOutlet weak var sapao: UIImageView!
    @IBOutlet weak var viewDialog: UIView!
    @IBOutlet weak var coinLabel: UILabel!
    
    var lightsOn = false
    var countLightsOn = 0
    var textTimer: Timer?
    var textSapao1 = """
    Okay, okay…. I know this Food-Ship doesn’t look like the best investment in the galaxy, but you'll see. This lil' baby is gonna make it rain!
    Oh! To begin working you need to go to the central food supply station. Who wants to drive? You can go in the front. The rest can sit in the back!
    """
    var textSapao2 = "C'mon! Just GO!"
    var kombiTimer: Timer?
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        authenticateLocalPlayer()
        
        let tapGestureRecognizerJoin = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        let tapGestureRecognizerHost = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        let tapGestureRecognizerText = UITapGestureRecognizer(target: self, action: #selector(screenTapped(tapGestureRecognizer:)))
        join.tag = 0
        join.isUserInteractionEnabled = true
        join.addGestureRecognizer(tapGestureRecognizerJoin)
        host.tag = 1
        host.isUserInteractionEnabled = true
        host.addGestureRecognizer(tapGestureRecognizerHost)
        viewDialog.addGestureRecognizer(tapGestureRecognizerText)
        viewDialog.isUserInteractionEnabled = true
        
        animateDialog(text: textSapao1)
        
        MusicPlayer.shared.play(.menu)
    }
    
    fileprivate func createKombiTimer() {
        kombiTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { (_) in
            //print("Timer called")
            
            self.countLightsOn += 1
            
            if self.lightsOn && self.countLightsOn >= 2 {
                UIView.transition(with: self.host,
                                  duration: 0.05,
                                  options: .transitionFlipFromRight,
                                  animations: { self.host.image = UIImage(named: "HOST - apagado") },
                                  completion: nil)
                self.lightsOn = false
                
                UIView.transition(with: self.join,
                                  duration: 0.05,
                                  options: .transitionFlipFromRight,
                                  animations: { self.join.image = UIImage(named: "JOIN - apagado") },
                                  completion: nil)
            } else if !self.lightsOn {
                UIView.transition(with: self.host,
                                  duration: 0.05,
                                  options: .transitionFlipFromRight,
                                  animations: { self.host.image = UIImage(named: "HOST - brilhando") },
                                  completion: nil)
                
                UIView.transition(with: self.join,
                                  duration: 0.05,
                                  options: .transitionFlipFromRight,
                                  animations: { self.join.image = UIImage(named: "JOIN - brilhando") },
                                  completion: nil)
                
                self.countLightsOn = 0
                self.lightsOn = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        MCManager.shared.resetSession()
    
        // TODO: Make update in UI with coin count
        setCoinsValue()
        
        createKombiTimer()
        kombiTimer?.fire()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        kombiTimer?.invalidate()
    }
    
    // MARK: - Methods
    func setCoinsValue() {
        databaseManager.getPlayerCoinCount { count in
            print("Current coin count: \(count)")
            DispatchQueue.main.async {
                self.coinLabel.text = count.description
            }
        }
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        //viewDialog.isHidden = true
        
        animateDialog(text: textSapao2)
        if tappedImage.tag == 0 {
            logger.log(message: "Join pressed!")
            EventLogger.shared.logButtonPress(buttonName: "inicial-join")
            coordinator?.waitingRoom(hosting: false)
            
        } else if tappedImage.tag == 1 {
            logger.log(message: "Host pressed!")
            EventLogger.shared.logButtonPress(buttonName: "inicial-host")
            coordinator?.waitingRoom(hosting: true)
        }
    }
    @objc func screenTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        textTimer?.invalidate()
        textLabel.text = textSapao1
    }
    func animateDialog(text: String) {
        self.textLabel.text = ""
        if textTimer != nil {
            textTimer!.invalidate()
            textTimer = nil
        }
        let charDelay = 0.03
        var timerRepetitions = 0
        let maxRepetitions = text.count
        var dialogText = text
        
        textTimer = Timer.scheduledTimer(withTimeInterval: charDelay, repeats: true, block: { (_) in
            let currentIndex = text.startIndex
            
            let text = (self.textLabel.text)!
            let addedText = String(dialogText.remove(at: currentIndex))
            
            self.textLabel.text = text + addedText
            
            timerRepetitions += 1
            if timerRepetitions >= maxRepetitions {
                
                self.textTimer?.invalidate()
                self.textTimer = nil
            }
            
        })
        
        textTimer?.fire()
    }
    
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.local
        
        localPlayer.authenticateHandler = { (viewController, error) -> Void in
            if viewController != nil {
                // 1. show login if player is not logged in
                self.present(viewController!, animated: true, completion: nil)
            } else if localPlayer.isAuthenticated {
                // 2. player is already authenticated & logged in, load game center
                self.isGameCenterEnabled = true
                
                // get default leaderboard ID
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifer, error) in
                    if error != nil {
                        print(error)
                    } else {
                        self.defaultLeaderboard = leaderboardIdentifer!
                    }
                })
                
            } else {
                // 3. game center is not enabled on the users device
                self.isGameCenterEnabled = false
                print("Local player could not be authenticated!")
                print(error)
            }
        }
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func openLeaderboard(_ sender: Any) {
        let newVC = GKGameCenterViewController()
        newVC.gameCenterDelegate = self
        newVC.viewState = .default
        present(newVC, animated: true, completion: nil)
    }
    
}
