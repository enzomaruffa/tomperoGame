//
//  LANObservers.swift
//  Tompero
//
//  Observer protocols for the Network.framework-backed transport. These
//  replace `MCManagerDataObserver` / `MCManagerMatchmakingObserver` so
//  conformers no longer pull in `MultipeerConnectivity`.
//

import Foundation

protocol LANDataObserver: AnyObject {
    func receiveData(wrapper: WirePayload)
}

protocol LANMatchmakingObserver: AnyObject {
    func playerUpdate(player: String, state: PeerConnectionState)
    func playerListSent(playersWithStatus: [PeerWithStatus])
    func receiveGameRule(rule: GameRule)
}

extension LANMatchmakingObserver {
    func playerUpdate(player: String, state: PeerConnectionState) {}
    func playerListSent(playersWithStatus: [PeerWithStatus]) {}
    func receiveGameRule(rule: GameRule) {}
}
