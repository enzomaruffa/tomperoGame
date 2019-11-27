import UIKit
import MultipeerConnectivity

class InicialViewController: UIViewController, Storyboarded {
    
    // MARK: - Storyboarded
    static var storyboardName = "Main"
    
    // MARK: - Variables
    var location = CGPoint(x: 0, y: 0)
    weak var coordinator: MainCoordinator?
    
    // MARK: - Outlets
    @IBOutlet weak var person: UIImageView!
    @IBOutlet weak var join: UIImageView!
    @IBOutlet weak var host: UIImageView!
    
    //    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    //
    //        let touch : UITouch! =  touches.first! as UITouch
    //
    //        if person.frame.contains(touch.location(in: self.view)) {
    //            location = touch.location(in: self.view)
    //            person.center = location
    //        }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        for _ in 0..<10 {
            print("\n\n")
            let rule = GameRuleFactory.generateRule(difficulty: .easy, players: [MCPeerID(displayName: "1"), MCPeerID(displayName: "2"), MCPeerID(displayName: "3"), MCPeerID(displayName: "4")])

            
            for player in rule.playerTables.keys {
                print("\(player.displayName):")
                for table in rule.playerTables[player]! {
                    if table.type == .ingredient {
                        print("    \(table.type) | \(table.ingredient!)")
                    } else {
                        print("    \(table.type)")
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch : UITouch! =  touches.first! as UITouch
        
        if person.frame.contains(touch.location(in: self.view)) {
            //touch.location(in: self.view) == person.center {
            location = touch.location(in: self.view)
            person.center = location
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //            let touch: UITouch! =  touches.first! as UITouch
        if join.frame.intersects(person.frame) {
            // Currently joining
            coordinator?.waitingRoom(hosting: false)
            person.center = join.center
        } else if host.frame.intersects(person.frame) {
            // Currently hosting
            coordinator?.waitingRoom(hosting: true)
            person.center = host.center
        } else {
            person.center = CGPoint(x: view.frame.width/2, y: view.frame.height/1.5)
        }
    }

}
