//
//  GameScene.swift
//  Tompero
//
//  Created by Vinícius Binder on 22/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Combine
import SpriteKit
import GameplayKit

// swiftlint:disable force_cast
class GameScene: SKScene {

    private var cancellables = Set<AnyCancellable>()

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

    // MARK: - Scene graph references

    /// Local player display name. Convenience for legacy code paths.
    var player: String { context?.player ?? LANConnectionManager.shared.selfName }

    /// Other-player names in pipe order. Drives `MatchSceneRouting`.
    var players: [String] { context?.otherPlayers ?? [] }

    var stations: [StationNode] = []
    var shelves: [StationNode] { stations.filter({ $0.stationType == .shelf }) }
    var pipes: [StationNode] { stations.filter({ $0.stationType == .pipe }) }
    var hatch: StationNode { stations.first(where: { $0.stationType == .hatch })! }
    var firstEmptyShelf: StationNode? { shelves.first(where: { $0.isEmpty }) }

    var orderListNode: OrderListNode!

    // MARK: - Animation Variables
    var stationsAnimationsRunning = false

    // Disconnect-recovery overlay — built lazily on first peer drop so
    // didMove doesn't allocate it for matches that never disconnect.
    private var reconnectionOverlay: ReconnectionOverlayController?

    // Teleport variables
    private var teleportAnimationNode: SKSpriteNode!
    private var teleportAnimationFrames: [SKTexture]!
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

        // Game-event stream — typed payloads coming off GameConnectionManager.
        GameConnectionManager.shared.events
            .sink { [weak self] event in
                self?.handle(gameEvent: event)
            }
            .store(in: &cancellables)

        // Matchmaking stream — reconnect overlay watches player state changes.
        LANConnectionManager.shared.matchmakingEvents
            .sink { [weak self] event in
                self?.handle(matchmakingEvent: event)
            }
            .store(in: &cancellables)

        setupOrderListNode()
        setupStations()
        setupShelves()
        setupPiping()
        setupHUD()
        setupBackground()

        SFXPlayer.shared.roundStarted.play()
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
    
    func setupOrderListNode() {
        orderListNode = (childNode(withName: "orders") as! OrderListNode)
        orderListNode.texture = SKTexture(imageNamed: "OrderList" + context.playerColor)
    }

    func setupStations() {
        let tables = context.tables
        Log.game.info("setupStations: \(tables.count) tables for player \(self.context.player, privacy: .public)")

        var nodes: [StationNode] = []
        for table in tables {
            switch table.type {
            case .chopping:
                nodes.append(BoardNode())
            case .cooking:
                nodes.append(StoveNode())
            case .frying:
                nodes.append(FryerNode())
            case .plate:
                nodes.append(PlateBoxNode())
            case .ingredient:
                if let ingredient = table.ingredient {
                    nodes.append(IngredientBoxNode(ingredient: ingredient))
                } else {
                    Log.game.error("setupStations: ingredient table has nil ingredient")
                }
            case .empty:
                nodes.append(StationNode(stationType: .empty))
            }
        }
        stations = nodes

        for (index, station) in stations.enumerated() {
            station.routing = self
            let node = station.spriteNode
            let pos = scene!.size.width / 2 - node.size.width / 2
            let xPositions: [CGFloat] = [-pos, 0.0, pos]
            let xPos = index < xPositions.count ? xPositions[index] : 0
            node.position = CGPoint(x: xPos, y: CGFloat(station.spriteYPos))
            self.addChild(node)
        }
    }
    
    func createTeleporterAnimation(_ teleporterNode: SKSpriteNode) {
        let teleportAtlas = SKTextureAtlas(named: "Teleport" + context.playerColor)
        teleportAnimationFrames = []
        for currentAnimation in 0..<teleportAtlas.textureNames.count {
            let teleportFrameName = "teleport\(currentAnimation > 9 ? currentAnimation.description : "0" + currentAnimation.description)"
            teleportAnimationFrames.append(teleportAtlas.textureNamed(teleportFrameName))
        }

        teleportAnimationNode = SKSpriteNode(texture: teleportAnimationFrames[0])
        self.addChild(teleportAnimationNode)

        teleportAnimationNode.position = teleporterNode.position + CGPoint(x: -8, y: -(teleporterNode.size.height + 8))
        teleportAnimationNode.zPosition = 60
    }

    func setupShelves() {
        let shelves: [StationNode] = [
            ShelfNode(node: self.childNode(withName: "shelf1") as! SKSpriteNode),
            ShelfNode(node: self.childNode(withName: "shelf2") as! SKSpriteNode),
            ShelfNode(node: self.childNode(withName: "shelf3") as! SKSpriteNode),
            DeliveryNode(node: self.childNode(withName: "delivery") as! SKSpriteNode)
        ]
        shelves.forEach { $0.routing = self }
        stations.append(contentsOf: shelves)

        (self.childNode(withName: "target") as! SKSpriteNode).texture = SKTexture(imageNamed: "Target" + context.playerColor)

        let teleporterNode = (self.childNode(withName: "teleporter") as! SKSpriteNode)
        teleporterNode.texture = SKTexture(imageNamed: "Teleporter" + context.playerColor)

        createTeleporterAnimation(teleporterNode)
    }

    func setupPiping() {
        for (index, color) in context.peerColors.enumerated() {
            let pipeNode = self.childNode(withName: "pipeArea" + (index + 1).description) as! SKSpriteNode
            let pipeImage = self.childNode(withName: "pipe" + (index + 1).description) as! SKSpriteNode
            pipeNode.name = "pipe" + (index + 1).description
            if context.playerOrder[index + 1] != "__empty__" {
                pipeImage.texture = SKTexture(imageNamed: "Pipe" + color)
                let pipe = PipeNode(node: pipeNode)
                pipe.routing = self
                stations.append(pipe)
            } else {
                pipeImage.texture = SKTexture(imageNamed: "PipeClosed" + color)
            }
        }

        let hatch = HatchNode(node: self.childNode(withName: "hatch") as! SKSpriteNode)
        hatch.routing = self
        stations.append(hatch)
    }

    func setupBackground() {
        let background = self.childNode(withName: "background") as! SKSpriteNode
        background.texture = SKTexture(imageNamed: "BackgroundXL" + context.playerColor)
    }

    func setupHUD() {
        let timerContainer = self.childNode(withName: "timerContainer") as! SKSpriteNode
        timerContainer.texture = SKTexture(imageNamed: "Timer" + context.playerColor)

        updateTimerUI()
        updateCoinsUI()
    }
    
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
            hatch.playAnimation()
            stationsAnimationsRunning = true
        } else if !isMoving && stationsAnimationsRunning {
            pipes.forEach({ $0.stopAnimation() })
            hatch.stopAnimation()
            stationsAnimationsRunning = false
        }
    }
    
    func endMatch(error: Bool = false) {
        guard !state.ended else { return }
        state.ended = true
        self.isPaused = true
        stations.forEach({ $0.stopAnimation() })

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
        let timePerFrame = TimeInterval(teleportDuration) / TimeInterval(teleportAnimationFrames.count)
        SFXPlayer.shared.teleporter.play()
        teleportAnimationNode.run(SKAction.animate(
            with: teleportAnimationFrames,
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
        updateCoinsUI()
        return true
    }

    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        guard !state.ended else { return }
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
        let timerLabel = self.childNode(withName: "timerLabel") as! SKLabelNode

        var currentSeconds = max(Int(ceil(clock.timeRemaining)), 0)
        let currentMinutes = currentSeconds / 60
        currentSeconds -= (currentMinutes * 60)

        timerLabel.text = "\(currentMinutes):\(currentSeconds > 9 ? currentSeconds.description : "0" + currentSeconds.description)"
    }

    func updateCoinsUI() {
        let coinsLabel = self.childNode(withName: "coinsLabel") as! SKLabelNode
        coinsLabel.text = "\(state.totalPoints)"
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
}

// MARK: - Game event handlers
extension GameScene {

    fileprivate func handle(gameEvent: GameEvent) {
        switch gameEvent {
        case .plate(let plate):
            receivePlate(plate: plate)
        case .ingredient(let ingredient):
            receiveIngredient(ingredient: ingredient)
        case .orders(let orders):
            receiveOrders(orders: orders)
        case .deliveryNotification(let notification):
            receiveDeliveryNotification(notification: notification)
        case .statistics(let statistics):
            receiveStatistics(statistics: statistics)
        }
    }

    fileprivate func receivePlate(plate: Plate) {
        Log.game.debug("Received plate with ingredients \(plate.ingredients.map({ type(of: $0) }))")
        
        guard let shelf = firstEmptyShelf else {
            return
        }
        
        let node = MovableSpriteNode(imageNamed: "Plate")
        shelf.plateNode = PlateNode(
            plate: plate,
            movableNode: node,
            currentLocation: shelf
        )
        shelf.plateNode?.updateTexture()
        node.zPosition = 2
        node.setScale(0)
        self.addChild(node)
        node.run(.scale(to: shelf.plateNodeScale, duration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.1))
    }
    
    fileprivate func receiveIngredient(ingredient: Ingredient) {
        Log.game.debug("Received ingredient with prefix \(ingredient.texturePrefix) and state \(ingredient.currentState.rawValue)")
        
        guard let shelf = firstEmptyShelf else {
            return
        }
        
        let node = MovableSpriteNode(imageNamed: ingredient.textureName)
        shelf.ingredientNode = IngredientNode(
            ingredient: ingredient,
            movableNode: node,
            currentLocation: shelf
        )
        shelf.ingredientNode?.checkTextureChange()
        node.zPosition = 2
        node.setScale(0)
        self.addChild(node)
        node.run(.scale(to: shelf.plateNodeScale, duration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.1))
    }
    
    fileprivate func receiveOrders(orders: [Order]) {
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

    fileprivate func receiveDeliveryNotification(notification: OrderDeliveryNotification) {
        guard notification.success else { return }
        state.recordDelivery(coins: notification.coinsAdded)
        SFXPlayer.shared.cashRegister.play()
        updateCoinsUI()
    }

    fileprivate func receiveStatistics(statistics: MatchStatistics) {
        endMatch()
        DispatchQueue.main.async { [weak self] in
            self?.onMatchEnd?(statistics)
        }
    }
}

extension GameScene {

    fileprivate func handle(matchmakingEvent: LANMatchmakingEvent) {
        if case .playerUpdate(let player, let state) = matchmakingEvent {
            playerUpdate(player: player, state: state)
        }
    }

    fileprivate func playerUpdate(player: String, state: PeerConnectionState) {
        // A bare .notConnected used to end the match instantly. With the
        // reconnect work in PR #6 a drop is often transient (background, brief
        // Wi-Fi loss), so we now hold the match paused for a 30s grace window
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
