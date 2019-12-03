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
    @IBOutlet weak var person: UIImageView!
    @IBOutlet weak var join: UIImageView!
    @IBOutlet weak var host: UIImageView!
    @IBOutlet weak var airGIF: UIImageView!
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.person.center = CGPoint(x: view.frame.width/2, y: view.frame.height/1.5)
    }
    
    // MARK: - Methods
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch : UITouch! =  touches.first! as UITouch
        
        if animationTimer == nil {
            animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (_) in
                self.playAnimatedSpaceship()
            })
            animationTimer!.fire()
        }
    
        if person.frame.contains(touch.location(in: self.view)) {
            //touch.location(in: self.view) == person.center {
            location = touch.location(in: self.view)
            person.center = location
        }
    }
    
    func playAnimatedSpaceship() {
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveLinear , animations: {
            self.person.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/8))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveLinear , animations: {
                    self.person.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi/8))
                })
            }
        })
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.shapeLayer?.removeFromSuperlayer()
        animationTimer?.invalidate()
        self.person.transform = CGAffineTransform(rotationAngle: CGFloat(0))
        animationTimer = nil
        //            let touch: UITouch! =  touches.first! as UITouch
        if join.frame.intersects(person.frame) {
            // Currently joining
            join.layer.removeAllAnimations()
            coordinator?.waitingRoom(hosting: false)
            person.center = join.center
            host.layer.removeAllAnimations()
        } else if host.frame.intersects(person.frame) {
            // Currently hosting
            host.layer.removeAllAnimations()
            join.layer.removeAllAnimations()
            coordinator?.waitingRoom(hosting: true)
            person.center = host.center
        } else {
            person.center = CGPoint(x: view.frame.width/2, y: view.frame.height/1.5)
        }
    }
    
}
