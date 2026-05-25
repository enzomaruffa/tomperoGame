//
//  MatchSceneRouting.swift
//  Tompero
//
//  Lets PlateNode / IngredientNode talk back to the scene without
//  force-casting `parent as! GameScene`. The scene conforms; the box
//  + shelf + pipe stations carry a weak reference; the nodes use that
//  reference when they need to route a payload (the .pipe move case)
//  or attempt a delivery (the .delivery case).
//
//  Without this protocol, the move-handling code on PlateNode and
//  IngredientNode keeps GameScene as a required concrete type and the
//  scene can't actually shrink.
//

import Foundation

protocol MatchSceneRouting: AnyObject {
    /// Map a pipe sprite name ("pipe1" / "pipe2" / "pipe3") to the display
    /// name of the peer that pipe sends to. Returns nil for an unknown name.
    func remotePlayer(forPipeName name: String) -> String?

    /// Forwarded by `PlateNode` when it lands on the delivery teleporter.
    /// Returns true on a successful delivery (caller plays the success VFX).
    func attemptDelivery(plate: Plate) -> Bool
}
