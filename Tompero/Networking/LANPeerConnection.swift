//
//  LANPeerConnection.swift
//  Tompero
//

import Foundation
import Network

/// One TCP pipe to a single remote peer. Owns the `NWConnection`, the framing
/// codec, the handshake handshake, and the per-connection state. The manager
/// keeps a `LANPeerConnection` per known peer.
///
/// Connections are bidirectional and symmetric — once handshake completes the
/// same object handles inbound and outbound traffic regardless of who dialed
/// whom.
final class LANPeerConnection {

    enum Direction {
        /// We opened this connection (we know the remote endpoint already).
        case outbound
        /// Remote opened this connection (we'll learn who they are from the
        /// handshake frame).
        case inbound
    }

    weak var delegate: LANPeerConnectionDelegate?

    let direction: Direction
    private let nwConnection: NWConnection
    private let queue: DispatchQueue
    private let codec = LANFrameCodec()

    /// Endpoint we dialed (outbound connections only). Persisted so the
    /// manager can attempt a reconnect after a transient drop.
    let remoteEndpoint: NWEndpoint?

    /// Identity of the remote peer. nil until the handshake frame arrives
    /// (and, for outbound connections, until we've at least dialed — we
    /// don't know who's at the other end of a Bonjour endpoint until they
    /// announce themselves).
    private(set) var remoteIdentity: PeerIdentity?

    private(set) var state: PeerConnectionState = .notConnected

    private var hasSentHandshake = false

    // Heartbeat. We send a ping every `heartbeatInterval`; if no traffic
    // (any frame, not just pongs) arrives within `heartbeatTimeout`, we
    // declare the link dead and tear down.
    private static let heartbeatInterval: TimeInterval = 2
    private static let heartbeatTimeout: TimeInterval = 6
    private var heartbeatTimer: DispatchSourceTimer?
    private var lastInboundActivity: Date = .distantPast

    init(connection: NWConnection, direction: Direction, queue: DispatchQueue, remoteEndpoint: NWEndpoint? = nil) {
        self.nwConnection = connection
        self.direction = direction
        self.queue = queue
        self.remoteEndpoint = remoteEndpoint
    }

    func start() {
        nwConnection.stateUpdateHandler = { [weak self] state in
            self?.handleNetworkState(state)
        }
        nwConnection.start(queue: queue)
    }

    /// Tear down the connection. Safe to call multiple times.
    func cancel() {
        stopHeartbeat()
        nwConnection.cancel()
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        stopHeartbeat()
        lastInboundActivity = Date()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + Self.heartbeatInterval, repeating: Self.heartbeatInterval)
        timer.setEventHandler { [weak self] in
            self?.heartbeatTick()
        }
        heartbeatTimer = timer
        timer.resume()
    }

    private func stopHeartbeat() {
        heartbeatTimer?.cancel()
        heartbeatTimer = nil
    }

    private func heartbeatTick() {
        let elapsed = Date().timeIntervalSince(lastInboundActivity)
        if elapsed > Self.heartbeatTimeout {
            Log.network.warning("Heartbeat timeout (\(elapsed)s), dropping connection")
            cancel()
            return
        }
        sendFrame(.ping(LANPing(id: UUID())))
    }

    func sendHandshake(asHost: Bool) {
        guard !hasSentHandshake else { return }
        hasSentHandshake = true
        let frame: LANFrame = .handshake(
            LANHandshake(peer: LocalPeerIdentity.current, isHost: asHost)
        )
        sendFrame(frame)
    }

    func sendEnvelope(_ envelope: LANEnvelope) {
        sendFrame(.envelope(envelope))
    }

    private func sendFrame(_ frame: LANFrame) {
        guard let data = codec.encode(frame) else {
            Log.network.error("Failed to encode frame")
            return
        }
        nwConnection.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error {
                Log.network.error("Send error: \(String(describing: error), privacy: .public)")
                self?.cancel()
            }
        })
    }

    // MARK: - NWConnection wiring

    private func handleNetworkState(_ networkState: NWConnection.State) {
        switch networkState {
        case .setup, .preparing:
            transition(to: .connecting)
        case .waiting(let error):
            Log.network.debug("Waiting: \(String(describing: error), privacy: .public)")
            transition(to: .connecting)
        case .ready:
            transition(to: .connecting) // still "connecting" until handshake completes
            scheduleReceive()
            startHeartbeat()
        case .failed(let error):
            Log.network.error("Failed: \(String(describing: error), privacy: .public)")
            transition(to: .notConnected)
            delegate?.peerConnection(self, didDisconnectWithError: error)
        case .cancelled:
            transition(to: .notConnected)
            delegate?.peerConnection(self, didDisconnectWithError: nil)
        @unknown default:
            break
        }
    }

    private func scheduleReceive() {
        nwConnection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            guard let self else { return }

            if let data, !data.isEmpty {
                switch self.codec.decodeFrames(appending: data) {
                case .corrupt:
                    Log.network.error("Corrupt frame, dropping connection")
                    self.cancel()
                    return
                case .frames(let frames):
                    for frame in frames {
                        self.handleFrame(frame)
                    }
                }
            }

            if let error {
                Log.network.error("Receive error: \(String(describing: error), privacy: .public)")
                self.cancel()
                return
            }

            if isComplete {
                self.cancel()
                return
            }

            self.scheduleReceive()
        }
    }

    private func handleFrame(_ frame: LANFrame) {
        lastInboundActivity = Date()
        switch frame {
        case .handshake(let handshake):
            remoteIdentity = handshake.peer
            transition(to: .connected)
            delegate?.peerConnection(self, didCompleteHandshake: handshake)
        case .envelope(let envelope):
            delegate?.peerConnection(self, didReceive: envelope)
        case .ping(let ping):
            sendFrame(.pong(LANPong(id: ping.id)))
        case .pong:
            // lastInboundActivity already updated above — pong has no
            // additional semantic.
            break
        }
    }

    private func transition(to next: PeerConnectionState) {
        guard state != next else { return }
        state = next
        delegate?.peerConnection(self, didChangeState: next)
    }
}

protocol LANPeerConnectionDelegate: AnyObject {
    func peerConnection(_ connection: LANPeerConnection, didChangeState state: PeerConnectionState)
    func peerConnection(_ connection: LANPeerConnection, didCompleteHandshake handshake: LANHandshake)
    func peerConnection(_ connection: LANPeerConnection, didReceive envelope: LANEnvelope)
    func peerConnection(_ connection: LANPeerConnection, didDisconnectWithError error: Error?)
}
