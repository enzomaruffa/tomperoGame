//
//  PeerPickerView.swift
//  Tompero
//
//  Modal sheet listing peers currently advertising over Bonjour. Replaces
//  PeerPickerViewController. Auto-dismisses on the first successful handshake.
//

import SwiftUI

final class PeerPickerViewModel: ObservableObject, LANDiscoveryObserver, LANMatchmakingObserver {
    @Published var peers: [LANBrowser.DiscoveredPeer] = []
    @Published var connectedPeerName: String?

    init() {
        peers = LANConnectionManager.shared.discoveredPeers
        LANConnectionManager.shared.setDiscoveryObserver(self)
        LANConnectionManager.shared.subscribeMatchmakingObserver(observer: self)
    }

    deinit {
        LANConnectionManager.shared.setDiscoveryObserver(nil)
        LANConnectionManager.shared.unsubscribeMatchmakingObserver(observer: self)
    }

    func discoveryDidUpdate(peers: [LANBrowser.DiscoveredPeer]) {
        DispatchQueue.main.async {
            self.peers = peers
        }
    }

    func playerUpdate(player: String, state: PeerConnectionState) {
        if state == .connected {
            DispatchQueue.main.async {
                self.connectedPeerName = player
            }
        }
    }
}

struct PeerPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PeerPickerViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.peers.isEmpty {
                    Text(String(localized: "picker.empty"))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.peers, id: \.displayName) { peer in
                        Button(peer.displayName) {
                            LANConnectionManager.shared.invite(peer)
                        }
                    }
                }
            }
            .navigationTitle(Text(String(localized: "picker.title")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "alert.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onReceive(viewModel.$connectedPeerName.compactMap { $0 }) { _ in
                dismiss()
            }
        }
    }
}
