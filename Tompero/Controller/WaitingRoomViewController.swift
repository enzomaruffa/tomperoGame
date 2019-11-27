//
//  WaitingRoomViewController.swift
//  Tompero
//
//  Created by Vinícius Binder on 22/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class WaitingRoomViewController: UIViewController, Storyboarded {
    
    static var storyboardName = "WaitingRoom"
    weak var coordinator: MainCoordinator?
    
    var hosting = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if hosting {
            MCManager.shared.hostSession()
        } else {
            MCManager.shared.joinSession(presentingFrom: self, delegate: self)
        }
        
        MCManager.shared.subscribeMatchmakingObserver(observer: self)

        // Do any additional setup after loading the view.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

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
    
    func playerUpdate(player: String, state: MCSessionState) {
        print("\(player) | \(state.rawValue)")
    }
    
}
