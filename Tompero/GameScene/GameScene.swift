//
//  GameScene.swift
//  Tompero
//
//  Created by Vinícius Binder on 22/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import SpriteKit
import GameplayKit

// swiftlint:disable force_cast
class GameScene: SKScene {

    /// Owns the Combine subscriptions for inbound game + matchmaking events
    /// and dispatches them via the `MatchNetworkDelegate` protocol below.
    /// Set in `didMove` once the match state is configured.
    private var network: MatchNetworkAdapter!

    /// Notifies the SwiftUI host (GameContainerView) when pause state flips,
    /// so it can present/dismiss the full-screen SwiftUI pause overlay. Fires
    /// for both local taps and remote `.pauseRequest` broadcasts.
    var onPauseChanged: ((Bool) -> Void)?

    /// Tap delegate for the pause button. Holds a closure that broadcasts a
    /// `.pauseRequest(true)` to all peers.
    private var pauseButtonDelegate: TappableClosure?

    // MARK: - Host callbacks
    /// Fired when a successful match ends with final statistics; SwiftUI
    /// host pushes the statistics screen. Replaces direct coordinator access.
    var onMatchEnd: ((MatchStatistics) -> Void)?
    /// Fired on a match-aborting error (peer dropped with no recovery). The
    /// SwiftUI host pops to root.
    var onMatchError: (() -> Void)?

    // MARK: - Match configuration (set by GameContainerView before didMove)
    var hosting = false
    var rule: GameRule?

    // MARK: - Match-scoped domain types

    /// Derived per-match info — local player, peer order, colors, my tables.
    /// Populated in `didMove`.
    private(set) var context: MatchContext!

    /// Mutable match bookkeeping (orders, statistics, lifecycle flags).
    let state = MatchState()

    /// Counts down + fires under-15s warning + times-up callbacks.
    private(set) var clock = MatchClock()

    /// Host-only order spawn loop. Nil on joiners.
    private var orderGenerator: OrderGenerator?

    /// Output of `MatchSceneBuilder.build()`. Holds the stations array,
    /// teleporter sprite + frames, order list, HUD labels — i.e. every
    /// scene-graph reference the scene reads each frame.
    private var nodes: MatchSceneNodes!

    // MARK: - Scene graph references (convenience accessors)

    var player: String { context?.player ?? LANConnectionManager.shared.selfName }
    var players: [String] { context?.otherPlayers ?? [] }
    var stations: [StationNode] { nodes?.stations ?? [] }
    var shelves: [StationNode] { stations.filter({ $0.stationType == .shelf }) }
    var pipes: [StationNode] { stations.filter({ $0.stationType == .pipe }) }
    var hatch: StationNode? { stations.first(where: { $0.stationType == .hatch }) }
    var firstEmptyShelf: StationNode? { shelves.first(where: { $0.isEmpty }) }
    var orderListNode: OrderListNode! { nodes?.orderList }

    // MARK: - Animation Variables
    var stationsAnimationsRunning = false

    // Disconnect-recovery overlay — built lazily on first peer drop so
    // didMove doesn't allocate it for matches that never disconnect.
    private var reconnectionOverlay: ReconnectionOverlayController?

    /// Teleport animation duration in seconds (frames-per-second derived
    /// from `nodes.teleportFrames.count`).
    private let teleportDuration = 1
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {

        Log.game.info("GameScene.didMove view.bounds=\(view.bounds.debugDescription, privacy: .public) scene.size=\(self.size.debugDescription, privacy: .public)")

        // Scale view size to device. Design target is iPhone X Pro Max landscape.
        let desiredWidth = CGFloat(2436)
        let desiredHeight = CGFloat(1154)

        var currentViewSize = self.viewSizeInLocalCoordinates()
        Log.game.info("currentViewSize before camera = \(currentViewSize.debugDescription, privacy: .public)")

        // Guard against zero-sized views — SwiftUI's SpriteView wrapper can
        // call didMove before final layout. A zero size would make the
        // requiredScale infinite and put the camera in geosynchronous orbit.
        let safeViewWidth = max(currentViewSize.width, 1)
        let safeViewHeight = max(currentViewSize.height, 1)
        let requiredScale = max(desiredWidth / safeViewWidth, desiredHeight / safeViewHeight)

        let cameraNode = SKCameraNode()
        self.camera = cameraNode
        addChild(cameraNode)

        cameraNode.setScale(requiredScale)

        currentViewSize = self.viewSizeInLocalCoordinates(ignoreCameraScale: false)
        let offset = (desiredHeight - currentViewSize.height) / 2
        cameraNode.position = CGPoint(x: 0, y: -offset)

        Log.game.info("camera scale=\(requiredScale) offset=\(offset)")

        guard let rule else {
            Log.game.error("GameScene.didMove: no rule set — match cannot start")
            return
        }
        context = MatchContext(rule: rule, hosting: hosting, player: LANConnectionManager.shared.selfName)

        configureClock()

        if hosting {
            orderGenerator = OrderGenerator()
            state.matchStatistics = MatchStatistics(ruleUsed: rule)
            EventLogger.shared.logMatchStart(
                withPlayerCount: context.playerOrder.filter({ $0 != "__empty__" }).count,
                andDifficulty: rule.difficulty
            )
        }

        network = MatchNetworkAdapter(state: state, delegate: self)

        nodes = MatchSceneBuilder(scene: self, context: context, routing: self).build()
        updateTimerUI()
        updateCoinsUI()
        positionPauseButton()

        configurePause()

        SFXPlayer.shared.roundStarted.play()

        #if DEBUG
        if ProcessInfo.processInfo.environment["UI_PREVIEW"] == "pause" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.setPaused(true)
            }
        }
        #endif
    }

    /// Pin the pause button to the top-*left* corner of the visible camera
    /// frame — the top-right is occupied by the coin + timer HUD, so the
    /// button was colliding with it there. Insets for the safe area so it
    /// clears the dynamic island / notch in either landscape orientation.
    private func positionPauseButton() {
        guard let camera else { return }
        let visible = viewSizeInLocalCoordinates(ignoreCameraScale: false)
        let cameraScale = camera.xScale
        let insets = view?.safeAreaInsets ?? .zero
        let sideInset = max(insets.left, insets.right) * cameraScale
        let topInset = max(insets.top, 0) * cameraScale
        let buttonHalf = nodes.pauseButton.size.width / 2
        let margin: CGFloat = 60
        nodes.pauseButton.position = CGPoint(
            x: -(visible.width / 2) + buttonHalf + margin + sideInset,
            y: visible.height / 2 - buttonHalf - margin - topInset
        )
    }

    private func configurePause() {
        pauseButtonDelegate = TappableClosure { [weak self] in
            guard let self, !self.state.ended else { return }
            self.setPaused(!self.state.paused)
        }
        nodes.pauseButton.delegate = pauseButtonDelegate
    }

    /// Apply a pause state change locally AND broadcast it. The local apply
    /// is essential — `dispatchOutgoing` never loops an envelope back to its
    /// sender, so without this the player who tapped pause would never see
    /// the overlay.
    private func setPaused(_ paused: Bool) {
        didReceivePauseRequest(paused: paused)
        LANConnectionManager.shared.send(.pauseRequest(paused))
    }

    /// Called by the SwiftUI pause overlay's RESUME button.
    func resumeMatch() {
        setPaused(false)
    }

    /// Called by the SwiftUI pause overlay's QUIT button.
    func quitMatch() {
        setPaused(false)
        onMatchError?()
    }

    private func configureClock() {
        clock.onSecondElapsed = { [weak self] in
            self?.updateTimerUI()
        }
        clock.onWarning = { [weak self] in
            guard let self else { return }
            self.state.endTimerPlayed = true
            SFXPlayer.shared.endTimer.play()
        }
        clock.onTimesUp = { [weak self] in
            guard let self else { return }
            self.state.timesUpPlayed = true
            SFXPlayer.shared.timesUp.play()
            MusicPlayer.shared.stop(.game)
            if self.hosting {
                self.stations.forEach({ $0.stopAnimation() })
                self.endMatch()
            }
        }
    }
    
    // The setup methods used to live here — now in MatchSceneBuilder.

    // MARK: - Game Logic

    /// Walk the order list ticking each one's clock; expire any past-due
    /// orders on the host (joiners just observe via the broadcast that the
    /// host sends after removing). The host's spawn cadence lives in
    /// `OrderGenerator` and is driven from `update(_:)`.
    fileprivate func updateOrders() {
        for (index, order) in state.orders.enumerated().reversed() {
            order.timeLeft -= 1 / 60

            if hosting, order.timeLeft <= 0.0 {
                let totalActions = order.ingredients.map({ $0.numberOfActionsTilReady }).reduce(0, +)
                EventLogger.shared.logOrderResult(
                    success: false,
                    actionCount: totalActions,
                    ingredientCount: order.ingredients.count,
                    difficulty: context.rule.difficulty
                )
                state.removeOrder(at: index)
                GameConnectionManager.shared.sendEveryone(orderList: state.orders)
                updateOrderUI(state.orders)
            }
        }
        orderListNode.update()
    }

    /// Drives the host-only spawn loop. Plays SFX, animates the order list,
    /// broadcasts the new order to joiners. Joiners get the order via the
    /// `.orders` payload subscription instead.
    private func tickHostOrderGenerator() {
        guard hosting, let generator = orderGenerator else { return }
        let spawned = generator.tick(state: state, rule: context.rule) { _ in
            if state.firstOrder {
                SFXPlayer.shared.orderUp.play()
                orderListNode.jump()
            } else {
                orderListNode.open()
            }
        }
        if spawned {
            updateOrderUI(state.orders)
            GameConnectionManager.shared.sendEveryone(orderList: state.orders)
            if !clock.didStart {
                clock.start()
            }
            if state.orders.count == 1 && !state.firstOrder {
                state.firstOrder = true
                MusicPlayer.shared.play(.game)
            }
        }
    }
    
    fileprivate func checkAnimations() {
        let isMoving = !stations.filter({ ($0.ingredientNode?.moving ?? false || $0.plateNode?.moving ?? false) }).isEmpty
        
        if isMoving && !stationsAnimationsRunning {
            pipes.forEach({ $0.playAnimation() })
            hatch?.playAnimation()
            stationsAnimationsRunning = true
        } else if !isMoving && stationsAnimationsRunning {
            pipes.forEach({ $0.stopAnimation() })
            hatch?.stopAnimation()
            stationsAnimationsRunning = false
        }
    }
    
    func endMatch(error: Bool = false) {
        guard !state.ended else { return }
        state.ended = true
        self.isPaused = true
        stations.forEach({ $0.stopAnimation() })

        if !error {
            // Broadcast our own action tally before the .statistics
            // payload so peers can render awards on the StatisticsView.
            // (The receive guard in MatchNetworkAdapter lets .playerAwards
            // through even after `state.ended` flips on the receiver.)
            LANConnectionManager.shared.send(
                .playerAwards(player: context.player, stats: state.myActions)
            )
        }

        if hosting && !error, let stats = state.matchStatistics {
            EventLogger.shared.logMatchEnd(
                withPlayerCount: context.playerOrder.filter({ $0 != "__empty__" }).count,
                andDifficulty: context.rule.difficulty
            )
            GameConnectionManager.shared.sendEveryone(statistics: stats)
            onMatchEnd?(stats)
        }

        if error {
            MusicPlayer.shared.stop(.game)
            onMatchError?()
        }
    }

    func makeDelivery(plate: Plate) -> Bool {
        let frames = nodes.teleportFrames
        let timePerFrame = TimeInterval(teleportDuration) / TimeInterval(frames.count)
        SFXPlayer.shared.teleporter.play()
        nodes.teleportAnimationNode.run(SKAction.animate(
            with: frames,
            timePerFrame: timePerFrame,
            resize: false,
            restore: true)
        )

        let totalActions = plate.ingredients.map({ $0.numberOfActionsTilReady }).reduce(0, +)
        let outcome = DeliveryScorer.score(
            plate: plate,
            against: state.orders,
            difficulty: context.rule.difficulty
        )

        if !outcome.success {
            let notification = OrderDeliveryNotification(playerName: context.player, success: false, coinsAdded: 0)
            GameConnectionManager.shared.sendEveryone(deliveryNotification: notification)
            EventLogger.shared.logPlateDeliver(success: false, actionCount: totalActions, ingredientCount: plate.ingredients.count)
            FloatingTextNode.spawn(
                text: "MISS",
                color: UIColor(red: 0.95, green: 0.30, blue: 0.30, alpha: 1),
                at: nodes.teleportAnimationNode.position,
                in: self
            )
            Haptics.failure()
            updateOrderUI(state.orders)
            return false
        }

        EventLogger.shared.logPlateDeliver(success: true, actionCount: totalActions, ingredientCount: plate.ingredients.count)
        EventLogger.shared.logOrderResult(success: true, actionCount: totalActions, ingredientCount: plate.ingredients.count, difficulty: context.rule.difficulty)

        let notification = OrderDeliveryNotification(playerName: context.player, success: true, coinsAdded: outcome.coinsAdded)
        GameConnectionManager.shared.sendEveryone(deliveryNotification: notification)

        if let index = outcome.matchedOrderIndex {
            state.removeOrder(at: index)
        }

        GameConnectionManager.shared.sendEveryone(orderList: state.orders)

        state.resetSpawnCounter()
        updateOrderUI(state.orders)
        state.recordDelivery(coins: outcome.coinsAdded)
        state.myActions.ordersDelivered += 1
        updateCoinsUI()

        FloatingTextNode.spawn(
            text: "+\(outcome.coinsAdded)",
            color: UIColor(red: 1.0, green: 0.83, blue: 0.25, alpha: 1),
            at: nodes.teleportAnimationNode.position,
            in: self
        )
        camera?.run(SKAction.cameraShake(amplitude: 12, duration: 0.25))
        Haptics.success()
        return true
    }

    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        guard !state.ended, !state.paused else { return }
        stations.forEach({ $0.update() })
        checkAnimations()
        updateOrders()
        tickHostOrderGenerator()
        clock.tick()
    }

    // MARK: - UI Updates
    func updateOrderUI(_ orders: [Order]) {
        orderListNode.updateList(orders)
    }

    func updateTimerUI() {
        guard let nodes else { return }
        var currentSeconds = max(Int(ceil(clock.timeRemaining)), 0)
        let currentMinutes = currentSeconds / 60
        currentSeconds -= (currentMinutes * 60)
        nodes.timerLabel.text = "\(currentMinutes):\(currentSeconds > 9 ? currentSeconds.description : "0" + currentSeconds.description)"
    }

    func updateCoinsUI() {
        nodes?.coinsLabel.text = "\(state.totalPoints)"
    }
}

// MARK: - MatchSceneRouting
extension GameScene: MatchSceneRouting {
    func remotePlayer(forPipeName name: String) -> String? {
        let peers = context.otherPlayers
        switch name {
        case "pipe1": return peers.indices.contains(0) ? peers[0] : nil
        case "pipe2": return peers.indices.contains(1) ? peers[1] : nil
        case "pipe3": return peers.indices.contains(2) ? peers[2] : nil
        default: return nil
        }
    }

    func attemptDelivery(plate: Plate) -> Bool {
        return makeDelivery(plate: plate)
    }

    func recordAction(_ kind: MatchActionKind) {
        switch kind {
        case .chop: state.myActions.chopActions += 1
        case .cook: state.myActions.cookActions += 1
        case .fry: state.myActions.fryActions += 1
        case .plateCreated: state.myActions.platesCreated += 1
        case .pipeForward: state.myActions.pipeForwards += 1
        case .orderDelivered: state.myActions.ordersDelivered += 1
        }
    }
}

// MARK: - MatchNetworkDelegate
extension GameScene: MatchNetworkDelegate {

    func didReceivePlate(_ plate: Plate) {
        guard let shelf = firstEmptyShelf else { return }
        let node = MovableSpriteNode(imageNamed: "Plate")
        shelf.plateNode = PlateNode(plate: plate, movableNode: node, currentLocation: shelf)
        shelf.plateNode?.updateTexture()
        node.zPosition = 2
        node.setScale(0)
        self.addChild(node)
        node.run(.scale(to: shelf.plateNodeScale, duration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.1))
    }

    func didReceiveIngredient(_ ingredient: Ingredient) {
        guard let shelf = firstEmptyShelf else { return }
        let node = MovableSpriteNode(imageNamed: ingredient.textureName)
        shelf.ingredientNode = IngredientNode(ingredient: ingredient, movableNode: node, currentLocation: shelf)
        shelf.ingredientNode?.checkTextureChange()
        node.zPosition = 2
        node.setScale(0)
        self.addChild(node)
        node.run(.scale(to: shelf.plateNodeScale, duration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.1))
    }

    func didReceiveOrders(_ orders: [Order]) {
        state.orders = orders

        if state.firstOrder {
            SFXPlayer.shared.orderUp.play()
            orderListNode.jump()
        } else {
            orderListNode.open()
        }

        if orders.count == 1 && !state.firstOrder {
            state.firstOrder = true
            MusicPlayer.shared.play(.game)
        }

        if !clock.didStart && !orders.isEmpty {
            clock.start()
        }

        updateOrderUI(orders)
    }

    func didReceiveDelivery(_ notification: OrderDeliveryNotification) {
        guard notification.success else { return }
        state.recordDelivery(coins: notification.coinsAdded)
        SFXPlayer.shared.cashRegister.play()
        updateCoinsUI()
    }

    func didReceiveStatistics(_ statistics: MatchStatistics) {
        endMatch()
        DispatchQueue.main.async { [weak self] in
            self?.onMatchEnd?(statistics)
        }
    }

    func didReceivePlayerAwards(player: String, stats: PlayerAwardStats) {
        state.peerAwards[player] = stats
    }

    func didReceivePauseRequest(paused: Bool) {
        guard !state.ended else { return }
        state.paused = paused
        // SwiftUI host renders the full-screen pause overlay (reliable
        // coverage, unlike the camera-child SKNode it replaced).
        onPauseChanged?(paused)
    }

    func didReceivePeerUpdate(player: String, state: PeerConnectionState) {
        // A bare .notConnected used to end the match instantly. With the
        // reconnect work in PR #6 a drop is often transient (background, brief
        // Wi-Fi loss), so we hold the match paused for a 30s grace window
        // and only declare it over if the peer doesn't come back.
        guard view != nil else { return }

        let controller = reconnectionOverlay ?? makeReconnectionOverlay()
        switch state {
        case .notConnected, .connecting:
            controller.begin(for: player)
        case .connected:
            controller.end()
        }
    }

    private func makeReconnectionOverlay() -> ReconnectionOverlayController {
        let controller = ReconnectionOverlayController(scene: self) { [weak self] in
            self?.endMatch(error: true)
        }
        reconnectionOverlay = controller
        return controller
    }
}
