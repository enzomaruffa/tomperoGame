//
//  LANSecurity.swift
//  Tompero
//
//  TLS-over-Bonjour with a pre-shared key. Encrypts the wire so a passive
//  observer on the same LAN can't read game traffic.
//
//  Limits to be aware of: every device running the app holds the PSK in its
//  binary, so this stops *passive* eavesdropping but is not a real
//  authentication boundary against someone with the binary in hand. For a
//  private cooking game on a home network that's the right trade-off.
//

import Foundation
import Network
import Security

enum LANSecurity {

    // Bumping the version string invalidates older builds' ability to talk to
    // newer ones. Keep this in sync between all shipped binaries.
    private static let pskSecret = "spacespice-lan-psk-v1"
    private static let pskIdentity = "tompero-peer"

    /// Build a fresh `NWParameters` set up for peer-to-peer TCP with TLS 1.3
    /// PSK authentication. Use one of these per `NWListener` / `NWConnection`
    /// (parameters are configured at construction time and can't be reused
    /// across multiple endpoints).
    static func makeParameters() -> NWParameters {
        let tls = makeTLSOptions()
        let tcp = NWProtocolTCP.Options()
        let parameters = NWParameters(tls: tls, tcp: tcp)
        parameters.includePeerToPeer = true
        return parameters
    }

    private static func makeTLSOptions() -> NWProtocolTLS.Options {
        let options = NWProtocolTLS.Options()
        let secOptions = options.securityProtocolOptions

        let psk = dispatchData(from: pskSecret.data(using: .utf8)!)
        let identity = dispatchData(from: pskIdentity.data(using: .utf8)!)

        // Network.framework's PSK API takes dispatch_data_t. Swift's
        // DispatchData isn't auto-bridged, so unsafeBitCast hops the value
        // across the ABI without copying. The cast is safe because the
        // underlying storage is the same C type.
        sec_protocol_options_add_pre_shared_key(
            secOptions,
            unsafeBitCast(psk, to: dispatch_data_t.self),
            unsafeBitCast(identity, to: dispatch_data_t.self)
        )

        // TLS 1.3 ciphersuites; PSK extension binds the connection via the
        // identity above. We pin to AES-128-GCM-SHA256 so both ends agree
        // deterministically and we don't need to negotiate.
        sec_protocol_options_append_tls_ciphersuite(
            secOptions,
            tls_ciphersuite_t(rawValue: UInt16(TLS_AES_128_GCM_SHA256))!
        )

        return options
    }

    private static func dispatchData(from data: Data) -> DispatchData {
        data.withUnsafeBytes { raw in
            DispatchData(bytes: UnsafeRawBufferPointer(start: raw.baseAddress, count: data.count))
        }
    }
}
