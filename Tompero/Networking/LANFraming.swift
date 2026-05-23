//
//  LANFraming.swift
//  Tompero
//

import Foundation

/// Length-prefixed frame codec for a single TCP stream.
///
/// Wire format per frame:
/// ```
/// [4 bytes big-endian UInt32 length][N bytes JSON-encoded LANFrame]
/// ```
///
/// `decodeFrames(appending:)` is the only entry point on the read side — feed
/// it whatever chunk `NWConnection.receive` delivered and it returns any
/// complete frames that became available, holding the residual bytes for the
/// next call.
final class LANFrameCodec {

    private var buffer = Data()
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    /// Maximum allowed frame payload size. Anything bigger almost certainly
    /// indicates a corrupted length header (or a malicious peer); we drop the
    /// connection rather than allocate gigabytes.
    static let maxFrameBytes: UInt32 = 4 * 1024 * 1024

    /// Encode a `LANFrame` for the wire. Returns nil if encoding fails so
    /// callers don't have to wire `throws` plumbing into the queue.
    func encode(_ frame: LANFrame) -> Data? {
        guard let payload = try? encoder.encode(frame) else { return nil }
        var data = Data(count: 4)
        data.withUnsafeMutableBytes { raw in
            raw.storeBytes(of: UInt32(payload.count).bigEndian, as: UInt32.self)
        }
        data.append(payload)
        return data
    }

    /// Result of feeding a chunk through the codec.
    enum DecodeResult {
        case frames([LANFrame])
        /// Stream is corrupted (oversized length or undecodable payload).
        /// The connection should be torn down.
        case corrupt
    }

    func decodeFrames(appending chunk: Data) -> DecodeResult {
        buffer.append(chunk)

        var output: [LANFrame] = []
        while true {
            guard buffer.count >= 4 else { break }
            let length = buffer.withUnsafeBytes { raw -> UInt32 in
                raw.load(as: UInt32.self).bigEndian
            }
            if length == 0 || length > LANFrameCodec.maxFrameBytes {
                return .corrupt
            }
            let totalNeeded = 4 + Int(length)
            guard buffer.count >= totalNeeded else { break }

            let payload = buffer.subdata(in: 4..<totalNeeded)
            buffer.removeSubrange(0..<totalNeeded)

            guard let frame = try? decoder.decode(LANFrame.self, from: payload) else {
                return .corrupt
            }
            output.append(frame)
        }
        return .frames(output)
    }
}
