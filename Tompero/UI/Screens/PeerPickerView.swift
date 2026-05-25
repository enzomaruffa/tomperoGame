//
//  PeerPickerView.swift
//  Tompero
//
//  Modal sheet listing peers currently advertising over Bonjour. Replaces
//  PeerPickerViewController. Auto-dismisses on the first successful handshake.
//

import Combine
import SwiftUI

final class PeerPickerViewModel: ObservableObject {
    @Published var peers: [LANBrowser.DiscoveredPeer] = []
    @Published var connectedPeerName: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        peers = LANConnectionManager.shared.discoveredPeers

        LANConnectionManager.shared.discoveredPeersChanged
            .receive(on: DispatchQueue.main)
            .assign(to: &$peers)

        LANConnectionManager.shared.matchmakingEvents
            .sink { [weak self] event in
                if case .playerUpdate(let player, let state) = event, state == .connected {
                    self?.connectedPeerName = player
                }
            }
            .store(in: &cancellables)
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
