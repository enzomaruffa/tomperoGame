//
//  LANFrameCodecTests.swift
//  TomperoTests
//

import XCTest
@testable import Tompero

final class LANFrameCodecTests: XCTestCase {

    func testRoundTripHandshake() throws {
        let codec = LANFrameCodec()
        let identity = PeerIdentity(id: UUID(), displayName: "Tester (1A2B)")
        let frame: LANFrame = .handshake(LANHandshake(peer: identity, isHost: true))

        let encoded = try XCTUnwrap(codec.encode(frame))

        guard case .frames(let decoded) = codec.decodeFrames(appending: encoded) else {
            return XCTFail("Expected frames, got corrupt")
        }
        XCTAssertEqual(decoded.count, 1)
        guard case .handshake(let h) = decoded[0] else {
            return XCTFail("Wrong frame variant")
        }
        XCTAssertEqual(h.peer.displayName, "Tester (1A2B)")
        XCTAssertTrue(h.isHost)
    }

    func testRoundTripPingPong() throws {
        let codec = LANFrameCodec()
        let id = UUID()

        let pingData = try XCTUnwrap(codec.encode(.ping(LANPing(id: id))))
        let pongData = try XCTUnwrap(codec.encode(.pong(LANPong(id: id))))

        guard case .frames(let decoded) = codec.decodeFrames(appending: pingData + pongData) else {
            return XCTFail("Expected frames")
        }
        XCTAssertEqual(decoded.count, 2)
    }

    func testPartialChunkReassembly() throws {
        let codec = LANFrameCodec()
        let id = UUID()
        let full = try XCTUnwrap(codec.encode(.ping(LANPing(id: id))))

        // Feed the codec one byte at a time — should accumulate until the
        // full frame is available and only then emit it.
        for byteIndex in 0..<(full.count - 1) {
            let chunk = full.subdata(in: byteIndex..<(byteIndex + 1))
            guard case .frames(let partial) = codec.decodeFrames(appending: chunk) else {
                return XCTFail("Expected frames")
            }
            XCTAssertTrue(partial.isEmpty, "Codec emitted a frame before all bytes arrived")
        }
        let last = full.subdata(in: (full.count - 1)..<full.count)
        guard case .frames(let final) = codec.decodeFrames(appending: last) else {
            return XCTFail("Expected frames")
        }
        XCTAssertEqual(final.count, 1)
    }

    func testRejectsOversizedFrame() {
        let codec = LANFrameCodec()
        // 4-byte length header claiming a 16 MB payload (over the 4 MB cap).
        var bogus = Data(count: 4)
        bogus.withUnsafeMutableBytes { raw in
            raw.storeBytes(of: UInt32(16 * 1024 * 1024).bigEndian, as: UInt32.self)
        }
        guard case .corrupt = codec.decodeFrames(appending: bogus) else {
            return XCTFail("Codec should have flagged oversized frame as corrupt")
        }
    }

    func testRejectsZeroLengthFrame() {
        let codec = LANFrameCodec()
        var bogus = Data(count: 4) // all zero → length 0
        bogus.withUnsafeMutableBytes { raw in
            raw.storeBytes(of: UInt32(0).bigEndian, as: UInt32.self)
        }
        guard case .corrupt = codec.decodeFrames(appending: bogus) else {
            return XCTFail("Codec should have flagged zero-length frame as corrupt")
        }
    }
}
