//
//  LANListener.swift
//  Tompero
//

import Foundation
import Network

/// Wraps `NWListener` to advertise this peer over Bonjour and accept incoming
/// TCP connections from other peers on the LAN.
final class LANListener {

    static let bonjourServiceType = "_cookios._tcp"

    weak var delegate: LANListenerDelegate?

    private var listener: NWListener?
    private let queue: DispatchQueue
    private let displayName: String

    init(displayName: String, queue: DispatchQueue) {
        self.displayName = displayName
        self.queue = queue
    }

    var isRunning: Bool { listener != nil }

    func start() throws {
        guard listener == nil else { return }

        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true

        let newListener = try NWListener(using: parameters)
        // Bonjour service name — visible to NWBrowser on the LAN. Set to the
        // displayName so the picker UI can label peers without a separate
        // discovery handshake.
        newListener.service = NWListener.Service(name: displayName, type: LANListener.bonjourServiceType)

        newListener.newConnectionHandler = { [weak self] connection in
            self?.delegate?.listener(self!, didAccept: connection)
        }

        newListener.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                self.delegate?.listenerDidBecomeReady(self)
            case .failed(let error):
                Log.network.error("Listener failed: \(String(describing: error), privacy: .public)")
                self.delegate?.listener(self, didFailWithError: error)
                self.stop()
            default:
                break
            }
        }

        listener = newListener
        newListener.start(queue: queue)
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }
}

protocol LANListenerDelegate: AnyObject {
    func listenerDidBecomeReady(_ listener: LANListener)
    func listener(_ listener: LANListener, didAccept connection: NWConnection)
    func listener(_ listener: LANListener, didFailWithError error: Error)
}
