import UIKit

class WaitingRoomViewController: UIViewController {

    @IBOutlet weak var topText: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var hatBlue: UIImageView!
    var timer = Timer()
    var counter = 0
    
    @objc func timerAction() {
        counter += 1
        //topText.text = "\(counter)"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.hatBlue.transform = CGAffineTransform(translationX: 400, y: -200)
        
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hatBlue.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
//        if counter >= 1 {
//            UIView.animate(withDuration: 2, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
//                self.hatBlue.transform = CGAffineTransform(translationX: 0, y: 0)
//        })
//        }
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapAnimations)))
    }
    
    @objc fileprivate func handleTapAnimations() {
        UIView.animate(withDuration: 2, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            //self.hatBlue.image = self.resizeImage(image: self.hatBlue.image!, targetSize: CGSize(width: 10, height: 20))
            self.hatBlue.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.hatBlue.transform = CGAffineTransform(translationX: 0, y: 0)
//        }
//            ,completion: { finish in
//
//            UIView.animate(withDuration: 1, delay: 0.25,options: UIView.AnimationOptions.curveEaseOut,animations: {
//            self.hatBlue.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
//
            }) { (_) in
//
        }
    }
    //)
    //}
    
    
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
