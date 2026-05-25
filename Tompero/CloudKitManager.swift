//
//  CloudKitManager.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 24/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import CloudKit
import Foundation

class CloudKitManager {

    static let shared = CloudKitManager()

    // Lazy so the CKContainer is only created on first database access.
    // Touching CKContainer at init time aborts on simulators without iCloud
    // entitlements.
    private lazy var container: CKContainer = CKContainer(identifier: "iCloud.com.enzomaruffa.spacespice")
    private lazy var publicDB: CKDatabase = container.publicCloudDatabase
    private lazy var privateDB: CKDatabase = container.privateCloudDatabase

    /// True only when CloudKit is actually usable. False under XCTest *and*
    /// under unsigned simulator builds without an iCloud account signed in —
    /// both cases would otherwise crash the process via `_os_crash`
    /// (uncatchable) the moment `CKContainer(identifier:)` is allocated.
    ///
    /// `ubiquityIdentityToken` returns nil when either the user isn't signed
    /// in to iCloud or the app's entitlement isn't honored (unsigned builds),
    /// so it's a single gate for both situations.
    private static let isAvailable: Bool = {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else {
            return false
        }
        return FileManager.default.ubiquityIdentityToken != nil
    }()

    private init() {}

    // MARK: - Public API

    func getPlayerCoinCount() async -> Int {
        guard Self.isAvailable else { return 0 }
        do {
            if let record = try await retrieveCoinRecord() {
                return record["amount"] as? Int ?? 0
            } else {
                await createCoinRecord()
                return 0
            }
        } catch {
            Log.network.error("getPlayerCoinCount failed: \(error.localizedDescription, privacy: .public)")
            return 0
        }
    }

    func setPlayerCoinCount(toValue value: Int) async {
        guard Self.isAvailable else { return }
        do {
            if let record = try await retrieveCoinRecord() {
                record.setValue(value, forKey: "amount")
                try await persist(record)
            } else {
                await createCoinRecord()
            }
        } catch {
            Log.network.error("setPlayerCoinCount failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func checkMatchExists(hash: String) async -> Bool {
        guard Self.isAvailable else { return false }
        do {
            return try await retrieveMatchHistoryRecord(hash: hash) != nil
        } catch {
            Log.network.error("checkMatchExists failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func addNewMatch(withHash hash: String, coinCount: Int) async {
        guard Self.isAvailable else { return }
        guard await !checkMatchExists(hash: hash) else { return }
        do {
            try await createMatchHistoryRecord(hash: hash, coinsAwarded: coinCount)
            let current = await getPlayerCoinCount()
            await setPlayerCoinCount(toValue: current + coinCount)
        } catch {
            Log.network.error("addNewMatch failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Private CK operations

    private func persist(_ record: CKRecord) async throws {
        _ = try await privateDB.save(record)
    }

    private func createCoinRecord() async {
        let record = CKRecord(recordType: "Coin")
        record.setValue(0, forKey: "amount")
        do {
            try await persist(record)
        } catch {
            Log.network.error("createCoinRecord failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func createMatchHistoryRecord(hash: String, coinsAwarded: Int) async throws {
        let record = CKRecord(recordType: "MatchHistory")
        record.setValue(coinsAwarded, forKey: "coinsAwarded")
        record.setValue(hash, forKey: "matchHash")
        try await persist(record)
    }

    private func retrieveCoinRecord() async throws -> CKRecord? {
        try await firstRecord(query: CKQuery(recordType: "Coin", predicate: NSPredicate(value: true)))
    }

    private func retrieveMatchHistoryRecord(hash: String) async throws -> CKRecord? {
        try await firstRecord(query: CKQuery(recordType: "MatchHistory", predicate: NSPredicate(format: "matchHash == %@", hash)))
    }

    private func firstRecord(query: CKQuery) async throws -> CKRecord? {
        let response = try await privateDB.records(
            matching: query,
            inZoneWith: CKRecordZone.default().zoneID,
            desiredKeys: nil,
            resultsLimit: 1
        )
        return response.matchResults.compactMap { try? $0.1.get() }.first
    }
}
