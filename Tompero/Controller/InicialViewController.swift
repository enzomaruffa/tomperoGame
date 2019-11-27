import UIKit
import MultipeerConnectivity

class InicialViewController: UIViewController {
    
    @IBOutlet weak var person: UIImageView!
    var location = CGPoint(x: 0, y: 0)
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
            MCManager.shared.joinSession(presentingFrom: self, delegate: self)
            person.center = join.center
        } else if host.frame.intersects(person.frame) {
            // Currently hosting
            MCManager.shared.hostSession()
            person.center = host.center
        } else {
            person.center = CGPoint(x: view.frame.width/2, y: view.frame.height/1.5)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func sendHi(_ sender: Any) {
        print("Send Hi")
        GameConnectionManager.shared.sendString(message: "Hi!")
    }
}

// MARK: - MCBrowserViewControllerDelegate Methods
extension InicialViewController: MCBrowserViewControllerDelegate {
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
    }
    
}

// MARK: - MCManagerMatchmakingObserver Methods
extension InicialViewController: MCManagerMatchmakingObserver {
    
    func playerUpdate(player: String, state: MCSessionState) {
        print("\(player) | \(state.rawValue)")
    }
    
}
