////
////  TesteView.swift
////  spaceProgram
////
////  Created by Pedro Vargas on 28/08/19.
////  Copyright © 2019 minichallenge. All rights reserved.
////
//
//import UIKit
//
//class DialogView: UIView {
//
//    @IBOutlet weak var viewDialog: UIView!
//    @IBOutlet weak var textLabel: UILabel!
//    
//    var textTimer: Timer?
//    
//    /*
//    // Only override draw() if you perform custom drawing.
//    // An empty implementation adversely affects performance during animation.
//    override func draw(_ rect: CGRect) {
//        // Drawing code
//    }
//    */
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        initialize()
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        initialize()
//    }
//
//    func initialize() {
//        //sprint("Init DialogView")
//    }
//    
//    func setupDialog(text: String) {
//
//        self.textLabel.text = ""
//        
//        if textTimer != nil {
//            
//            textTimer!.invalidate()
//            textTimer = nil
//        }
//        
//        let charDelay = 0.2
//        var timerRepetitions = 0
//        let maxRepetitions = text.count
//        var dialogText = text
//        
//        textTimer = Timer.scheduledTimer(withTimeInterval: charDelay, repeats: true, block: { (timer) in
//            let currentIndex = text.startIndex
//            
//            let text = (self.textLabel.text)!
//            let addedText = String(dialogText.remove(at: currentIndex))
//            
//            self.textLabel.text = text + addedText
//            
//            timerRepetitions += 1
//            if timerRepetitions >= maxRepetitions {
//                
//                self.textTimer?.invalidate()
//                self.textTimer = nil
//            }
//            
//        })
//        
//        textTimer?.fire()
//    }
//    
//}
