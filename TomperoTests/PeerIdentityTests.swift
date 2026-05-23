//
//  PeerIdentityTests.swift
//  TomperoTests
//

import XCTest
@testable import SpaceSpice

final class PeerIdentityTests: XCTestCase {

    func testPeerIdentityIsCodableRoundTrip() throws {
        let original = PeerIdentity(id: UUID(), displayName: "Tester (ABCD)")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PeerIdentity.self, from: encoded)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.displayName, original.displayName)
    }

    func testPeerWithStatusEqualityIgnoresIdentity() {
        let lhs = PeerWithStatus(name: "Alice", status: .connected)
        let rhs = PeerWithStatus(name: "Alice", status: .connected)
        XCTAssertEqual(lhs, rhs)

        rhs.status = .notConnected
        XCTAssertNotEqual(lhs, rhs)
    }

    func testPeerWithStatusCopyIsIndependent() {
        let original = PeerWithStatus(name: "Bob", status: .connecting)
        let copy = original.copy()
        copy.status = .connected
        XCTAssertEqual(original.status, .connecting)
        XCTAssertEqual(copy.status, .connected)
    }
}
