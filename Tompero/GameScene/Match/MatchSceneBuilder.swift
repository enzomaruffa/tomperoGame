//
//  MatchSceneBuilder.swift
//  Tompero
//
//  Owns scene-setup that used to live as a half-dozen `setupX()` methods on
//  GameScene. Builds the stations array (from the `MatchContext.tables`),
//  wires the shelves/pipes/hatch from the .sks scene graph, decorates
//  the background / target / teleporter with the player color, populates
//  the order list node, and returns typed references the scene reads
//  every frame (`timerLabel`, `coinsLabel`, `teleportAnimationNode`).
//
//  The private `SceneNodeLocator` quarantines the 15+ scattered
//  `childNode(withName:) as!` casts to one place with explicit assert
//  messages — if a .sks expectation breaks we now get "missing shelf2",
//  not "unwrapped nil somewhere".
//

import Foundation
import SpriteKit

struct MatchSceneNodes {
    /// All gameplay-affecting nodes (boxes, boards, shelves, pipes, hatch,
    /// delivery teleporter). Ordering: the per-player tables first (3
    /// entries), then the 3 shelves, the delivery, optional pipes, hatch.
    var stations: [StationNode]
    var teleporter: SKSpriteNode
    var teleportFrames: [SKTexture]
    var teleportAnimationNode: SKSpriteNode
    var orderList: OrderListNode
    var timerLabel: SKLabelNode
    var coinsLabel: SKLabelNode
    /// In-HUD pause button (camera-attached). Tap broadcasts a pause request.
    var pauseButton: TappableSpriteNode
}

final class MatchSceneBuilder {

    private let scene: SKScene
    private let context: MatchContext
    private weak var routing: MatchSceneRouting?
    private let locator: SceneNodeLocator

    init(scene: SKScene, context: MatchContext, routing: MatchSceneRouting?) {
        self.scene = scene
        self.context = context
        self.routing = routing
        self.locator = SceneNodeLocator(scene: scene)
    }

    /// Single entrypoint. Camera setup MUST run before this — the station
    /// position math reads `scene.size`.
    func build() -> MatchSceneNodes {
        let orderList = buildOrderList()
        let stations = buildTableStations() + buildShelvesAndDelivery() + buildPipesAndHatch()
        let (teleporter, teleportFrames, teleportAnimationNode) = buildTeleporter()
        decorateBackground()
        let (timerLabel, coinsLabel) = buildHUD()
        let pauseButton = buildPauseButton()
        return MatchSceneNodes(
            stations: stations,
            teleporter: teleporter,
            teleportFrames: teleportFrames,
            teleportAnimationNode: teleportAnimationNode,
            orderList: orderList,
            timerLabel: timerLabel,
            coinsLabel: coinsLabel,
            pauseButton: pauseButton
        )
    }

    /// Camera-attached pause button. Repositioned by `GameScene` to the
    /// visible top-left corner; the scene's `MatchSceneRouting` conformance
    /// assigns a tap delegate that broadcasts `.pauseRequest(true)`.
    /// Styled as a dark circle with a white "II" to match the menu HUD
    /// (gear / name tag) and the pause overlay's aesthetic.
    private func buildPauseButton() -> TappableSpriteNode {
        // Clear hit-target square (generous tap area); the visible chrome is
        // the child circle below.
        let size = CGSize(width: 150, height: 150)
        let button = TappableSpriteNode(color: .clear, size: size)
        button.name = "pauseButton"
        button.zPosition = 1200
        button.position = CGPoint(x: 1100, y: 450)

        let disc = SKShapeNode(circleOfRadius: 66)
        disc.fillColor = UIColor(red: 0.13, green: 0.11, blue: 0.26, alpha: 1)
        disc.strokeColor = UIColor.white.withAlphaComponent(0.55)
        disc.lineWidth = 5
        disc.zPosition = 0
        button.addChild(disc)

        let label = SKLabelNode(fontNamed: "TitilliumWeb-Bold")
        label.text = "II"
        label.fontSize = 72
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        button.addChild(label)

        if let camera = scene.camera {
            camera.addChild(button)
        } else {
            scene.addChild(button)
        }
        return button
    }

    // MARK: - Pieces

    private func buildOrderList() -> OrderListNode {
        let node = locator.orderList()
        node.texture = SKTexture(imageNamed: "OrderList" + context.playerColor)
        return node
    }

    /// The per-player table slots dictated by the procedurally-generated rule.
    /// Three nodes, left/center/right, hooked into `routing` for pipe sends.
    private func buildTableStations() -> [StationNode] {
        var nodes: [StationNode] = []
        for table in context.tables {
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
                    Log.game.error("MatchSceneBuilder: ingredient table has nil ingredient")
                }
            case .empty:
                nodes.append(StationNode(stationType: .empty))
            }
        }

        for (index, station) in nodes.enumerated() {
            station.routing = routing
            let sprite = station.spriteNode
            let pos = scene.size.width / 2 - sprite.size.width / 2
            let xPositions: [CGFloat] = [-pos, 0.0, pos]
            let xPos = index < xPositions.count ? xPositions[index] : 0
            sprite.position = CGPoint(x: xPos, y: CGFloat(station.spriteYPos))
            scene.addChild(sprite)
        }

        return nodes
    }

    private func buildShelvesAndDelivery() -> [StationNode] {
        let shelves: [StationNode] = [
            ShelfNode(node: locator.shelf(1)),
            ShelfNode(node: locator.shelf(2)),
            ShelfNode(node: locator.shelf(3)),
            DeliveryNode(node: locator.delivery())
        ]
        shelves.forEach { $0.routing = routing }
        locator.target().texture = SKTexture(imageNamed: "Target" + context.playerColor)
        return shelves
    }

    private func buildPipesAndHatch() -> [StationNode] {
        var nodes: [StationNode] = []
        for (index, color) in context.peerColors.enumerated() {
            let pipeArea = locator.pipeArea(index + 1)
            let pipeImage = locator.pipeImage(index + 1)
            pipeArea.name = "pipe" + (index + 1).description
            if context.playerOrder[index + 1] != "__empty__" {
                pipeImage.texture = SKTexture(imageNamed: "Pipe" + color)
                let pipe = PipeNode(node: pipeArea)
                pipe.routing = routing
                nodes.append(pipe)
            } else {
                pipeImage.texture = SKTexture(imageNamed: "PipeClosed" + color)
            }
        }
        let hatch = HatchNode(node: locator.hatch())
        hatch.routing = routing
        nodes.append(hatch)
        return nodes
    }

    private func buildTeleporter() -> (SKSpriteNode, [SKTexture], SKSpriteNode) {
        let teleporter = locator.teleporter()
        teleporter.texture = SKTexture(imageNamed: "Teleporter" + context.playerColor)

        let atlas = SKTextureAtlas(named: "Teleport" + context.playerColor)
        var frames: [SKTexture] = []
        for currentAnimation in 0..<atlas.textureNames.count {
            let frameName = "teleport\(currentAnimation > 9 ? currentAnimation.description : "0" + currentAnimation.description)"
            frames.append(atlas.textureNamed(frameName))
        }

        let animationNode = SKSpriteNode(texture: frames[0])
        scene.addChild(animationNode)
        animationNode.position = teleporter.position + CGPoint(x: -8, y: -(teleporter.size.height + 8))
        animationNode.zPosition = 60

        return (teleporter, frames, animationNode)
    }

    private func decorateBackground() {
        locator.background().texture = SKTexture(imageNamed: "BackgroundXL" + context.playerColor)
    }

    private func buildHUD() -> (SKLabelNode, SKLabelNode) {
        locator.timerContainer().texture = SKTexture(imageNamed: "Timer" + context.playerColor)
        return (locator.timerLabel(), locator.coinsLabel())
    }
}

// MARK: - Typed child lookup

/// Quarantines the 15+ scattered `childNode(withName:) as!` casts to one
/// place. Each accessor traps with a clear message if the .sks scene graph
/// is missing the expected node, instead of crashing at the use site with
/// an opaque unwrap nil.
private final class SceneNodeLocator {
    private let scene: SKScene

    init(scene: SKScene) {
        self.scene = scene
    }

    func orderList() -> OrderListNode { typed("orders") }
    func shelf(_ index: Int) -> SKSpriteNode { typed("shelf" + index.description) }
    func delivery() -> SKSpriteNode { typed("delivery") }
    func target() -> SKSpriteNode { typed("target") }
    func teleporter() -> SKSpriteNode { typed("teleporter") }
    func pipeArea(_ index: Int) -> SKSpriteNode { typed("pipeArea" + index.description) }
    func pipeImage(_ index: Int) -> SKSpriteNode { typed("pipe" + index.description) }
    func hatch() -> SKSpriteNode { typed("hatch") }
    func background() -> SKSpriteNode { typed("background") }
    func timerContainer() -> SKSpriteNode { typed("timerContainer") }
    func timerLabel() -> SKLabelNode { typed("timerLabel") }
    func coinsLabel() -> SKLabelNode { typed("coinsLabel") }

    private func typed<T: SKNode>(_ name: String) -> T {
        guard let node = scene.childNode(withName: name) as? T else {
            fatalError("MatchSceneBuilder: expected scene node named '\(name)' of type \(T.self) but it was missing or the wrong type")
        }
        return node
    }
}
