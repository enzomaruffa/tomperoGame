//
//  LANBrowser.swift
//  Tompero
//

import Foundation
import Network

/// Bonjour-based peer discovery via `NWBrowser`. Surfaces a snapshot of
/// currently-advertising peers; the manager decides who to dial.
final class LANBrowser {

    struct DiscoveredPeer: Hashable {
        let displayName: String
        let endpoint: NWEndpoint
    }

    weak var delegate: LANBrowserDelegate?

    private var browser: NWBrowser?
    private let queue: DispatchQueue

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    var isRunning: Bool { browser != nil }

    func start() {
        guard browser == nil else { return }

        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        let newBrowser = NWBrowser(
            for: .bonjour(type: LANListener.bonjourServiceType, domain: nil),
            using: parameters
        )

        newBrowser.browseResultsChangedHandler = { [weak self] results, _ in
            guard let self else { return }
            let peers: [DiscoveredPeer] = results.compactMap { result in
                guard case .service(let name, _, _, _) = result.endpoint else { return nil }
                return DiscoveredPeer(displayName: name, endpoint: result.endpoint)
            }
            self.delegate?.browser(self, didUpdate: peers)
        }

        newBrowser.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            if case .failed(let error) = state {
                Log.network.error("Browser failed: \(String(describing: error), privacy: .public)")
                self.delegate?.browser(self, didFailWithError: error)
                self.stop()
            }
        }

        browser = newBrowser
        newBrowser.start(queue: queue)
    }

    func stop() {
        browser?.cancel()
        browser = nil
    }
}

protocol LANBrowserDelegate: AnyObject {
    func browser(_ browser: LANBrowser, didUpdate peers: [LANBrowser.DiscoveredPeer])
    func browser(_ browser: LANBrowser, didFailWithError error: Error)
}
