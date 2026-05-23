# TomperoTests

Unit tests for the Tompero / SpaceSpice transport and game-logic layers.

## Adding this target to Xcode

The test source files live here, but the test target itself isn't wired into `Tompero.xcodeproj` yet (adding a new target safely needs Xcode). To wire it up:

1. Open `Tompero.xcworkspace`
2. **File → New → Target…** → **iOS** → **Unit Testing Bundle**
3. Set Product Name to `TomperoTests`, Bundle Identifier to `com.enzomaruffa.spacespice.tests`, Language to Swift, Target to Be Tested to `Tompero`
4. In the Project navigator, delete Xcode's auto-generated `TomperoTests.swift` and `Info.plist`
5. Right-click the new `TomperoTests` group → **Add Files to "Tompero"…** and add every `.swift` file in this directory plus this `Info.plist`
6. Build settings → set `IPHONEOS_DEPLOYMENT_TARGET = 15.0`, `SWIFT_VERSION = 5.10`
7. ⌘U should now run the three suites: `LANFrameCodecTests`, `LANReconnectPolicyTests`, `PeerIdentityTests`

## What's covered

- **`LANFrameCodec`** — handshake/ping/pong round-trip, partial-chunk reassembly, oversized-frame rejection, zero-length rejection
- **`LANReconnectPolicy`** — schedule saturation, budget exhaustion, reset
- **`PeerIdentity` / `PeerWithStatus`** — Codable round-trip, equality semantics, copy independence

This is starter coverage focused on the transport-layer pieces that are pure logic and easiest to exercise without a running iOS app. The bigger wins (`GameRuleFactory` determinism, `LANConnectionManager` end-to-end via two in-process managers wired by a stub `NWConnection`) are good follow-ups.
