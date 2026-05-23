//
//  PeerPickerViewController.swift
//  Tompero
//
//  Custom replacement for `MCBrowserViewController`. Shows peers currently
//  advertising on the LAN and lets the host tap one to invite. Lightweight —
//  no nib, programmatic only, presented modally from the waiting room.
//

import UIKit

protocol PeerPickerDelegate: AnyObject {
    func peerPickerDidFinish(_ picker: PeerPickerViewController)
    func peerPickerDidCancel(_ picker: PeerPickerViewController)
}

final class PeerPickerViewController: UIViewController {

    weak var delegate: PeerPickerDelegate?

    private let tableView = UITableView()
    private let emptyLabel = UILabel()
    private var peers: [LANBrowser.DiscoveredPeer] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        title = "Nearby Players"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "peer")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        emptyLabel.text = "Looking for nearby players…"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])

        peers = LANConnectionManager.shared.discoveredPeers
        LANConnectionManager.shared.setDiscoveryObserver(self)
        updateEmptyState()
    }

    private func updateEmptyState() {
        let hasPeers = !peers.isEmpty
        tableView.isHidden = !hasPeers
        emptyLabel.isHidden = hasPeers
    }

    deinit {
        LANConnectionManager.shared.setDiscoveryObserver(nil)
    }

    @objc private func cancelTapped() {
        delegate?.peerPickerDidCancel(self)
    }

    @objc private func doneTapped() {
        delegate?.peerPickerDidFinish(self)
    }
}

extension PeerPickerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        peers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "peer", for: indexPath)
        cell.textLabel?.text = peers[indexPath.row].displayName
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peer = peers[indexPath.row]
        LANConnectionManager.shared.invite(peer)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension PeerPickerViewController: LANDiscoveryObserver {
    func discoveryDidUpdate(peers: [LANBrowser.DiscoveredPeer]) {
        self.peers = peers
        tableView.reloadData()
        updateEmptyState()
    }
}
