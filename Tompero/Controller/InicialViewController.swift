import UIKit
import MultipeerConnectivity

class InicialViewController: UIViewController, Storyboarded {
    
    // MARK: - Storyboarded
    static var storyboardName = "Main"
    weak var shapeLayer: CAShapeLayer?
    
    // MARK: - Variables
    var location = CGPoint(x: 0, y: 0)
    weak var coordinator: MainCoordinator?
    var animationTimer: Timer?
    
    // MARK: - Outlets
    @IBOutlet weak var join: UIImageView!
    @IBOutlet weak var host: UIImageView!
    @IBOutlet weak var frente: UIImageView!
    @IBOutlet weak var traseira: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var textBox: UIImageView!
    @IBOutlet weak var sapao: UIImageView!
    @IBOutlet weak var viewDialog: UIView!
    
    var lightsOn = false
    var countLightsOn = 0
    var textTimer: Timer?
    var textSapao1 = "Olá, meu nome é Sapão e eu ainda não tenho fala definida \nPor favor, me ajude!"
    var textSapao2 = "Ainda não escolheu oque vai ser meu filho? Decide logo!"
    var kombiTimer: Timer?
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
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
        kombiTimer?.fire()
        
//
//        UIView.animate(withDuration: 1, delay: 0.0, options: [.repeat], animations: {
//            self.host.image =
//            print("Setting host on")
//        })
//        UIView.animate(withDuration: 1, delay: 1, options: [.repeat], animations: {
//            print("Setting host off")
//            self.host.image = UIImage(named: "HOST - apagado")
//        })
        
//        for difficulty in [GameDifficulty.easy, .medium, .hard] {
//            print("\n\n")
//            print("Game Rule with difficulty \(difficulty)")
//
//            let rule = GameRuleFactory.generateRule(difficulty: difficulty,
//                                                    players: [MCPeerID(displayName: "1"),
//                                                              MCPeerID(displayName: "2"),
//                                                              MCPeerID(displayName: "3"),
//                                                              MCPeerID(displayName: "4")])
//
//            for player in rule.playerTables.keys.sorted(by: {$0.displayName < $1.displayName}) {
//                print("\(player.displayName):")
//                for table in rule.playerTables[player]! {
//                    if table.type == .ingredient {
//                        print("    \(table.type) | \(table.ingredient!)")
//                    } else {
//                        print("    \(table.type)")
//                    }
//                }
//            }
//
//            print("\nSample orders: ")
//
//            for counter in 0..<3 {
//                print("\nOrder \(counter): ")
//                let order = rule.generateOrder()
//                for ingredient in order.ingredients {
//                    print(type(of: ingredient))
//                }
//                print("Total actions to prepare: \(order.ingredients.reduce(0, {$0 + $1.numberOfActionsTilReady}))")
//            }
//
//            print("\nSample counts: ")
//            var probabilityDict: [Int: Int]  = [:]
//            for _ in 0..<100 {
//                let order = rule.generateOrder()
//                let totalActions = order.ingredients.reduce(0, {$0 + $1.numberOfActionsTilReady})
//                probabilityDict[totalActions] = (probabilityDict[totalActions] ?? 0) + 1
//            }
//
//            for key in probabilityDict.keys.sorted() {
//                print("\(key): \(probabilityDict[key]!)")
//            }
//        }
        
        //airGIF.loadGif(name: "airR1")
        animateDialog(text: textSapao1)
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        MCManager.shared.resetSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        kombiTimer?.invalidate()
    }
    
    // MARK: - Methods
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        //viewDialog.isHidden = true
        
        animateDialog(text: textSapao2)
        if tappedImage.tag == 0 {
            print("CLICOU JOIN")
            coordinator?.waitingRoom(hosting: false)
            
        } else if tappedImage.tag == 1 {
            print("CLICOU HOST")
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
        let charDelay = 0.1
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
    
}
