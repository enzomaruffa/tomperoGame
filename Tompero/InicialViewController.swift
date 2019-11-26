import UIKit

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
            let touch : UITouch! =  touches.first! as UITouch
            if join.frame.intersects(person.frame) {
                person.center = join.center
            }
            else if host.frame.intersects(person.frame){
                person.center = host.center
            }
            else {
                person.center = CGPoint(x: view.frame.width/2, y: view.frame.height/1.5)
            }
        }
    override func viewDidLoad() {
            super.viewDidLoad()
        }
        
        
    }

