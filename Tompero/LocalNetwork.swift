//
//  LocalNetwork.swift
//  Tompero
//
//  Created by Enzo Maruffa on 05/04/22.
//  Copyright © 2022 Tompero. All rights reserved.
//

import UIKit
import Network

class LocalNetworkPermissionChecker {
    private var host: String
    private var port: UInt16
    private var checkPermissionStatus: DispatchWorkItem?
    
    private lazy var detectDeclineTimer: Timer? = Timer.scheduledTimer(
        withTimeInterval: .zero,
        repeats: false,
        block: { [weak self] _ in
            guard let checkPermissionStatus = self?.checkPermissionStatus else { return }
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: checkPermissionStatus)
        })
    
    init(host: String, port: UInt16, granted: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        self.host = host
        self.port = port
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationIsInBackground),
            name: UIApplication.willResignActiveNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationIsInForeground),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        
        actionRequestNetworkPermissions(granted: granted, failure: failure)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Creating a network connection prompts the user for permission to access the local network. We do not have the need to actually send anything over the connection.
    /// - Note: The user will only be prompted once for permission to access the local network. The first time they do this the app will be placed in the background while
    /// the user is being prompted. We check for this to occur. If it does we invalidate our timer and allow the user to make a selection. When the app returns to the foreground
    /// verify what they selected. If this is not the first time they are on this screen, the timer will not be invalidated and we will check the dispatchWorkItem block to see what
    /// their selection was previously.
    /// - Parameters:
    ///   - granted: Informs application that user has provided us with local network permission.
    ///   - failure: Something went awry.
    private func actionRequestNetworkPermissions(granted: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        guard let port = NWEndpoint.Port(rawValue: port) else { return }
        
        let connection = NWConnection(host: NWEndpoint.Host(host), port: port, using: .udp)
        connection.start(queue: .main)
        
        checkPermissionStatus = DispatchWorkItem(block: { [weak self] in
            if connection.state == .ready {
                self?.detectDeclineTimer?.invalidate()
                granted()
            } else {
                failure(nil)
            }
        })
        
        detectDeclineTimer?.fireDate = Date() + 1
    }
    
    /// Permission prompt will throw the application in to the background and invalidate the timer.
    @objc private func applicationIsInBackground() {
        detectDeclineTimer?.invalidate()
    }
    
    /// - Important: DispatchWorkItem must be called after 1sec otherwise we are calling before the user state is updated.
    @objc private func applicationIsInForeground() {
        guard let checkPermissionStatus = checkPermissionStatus else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: checkPermissionStatus)
    }
}
