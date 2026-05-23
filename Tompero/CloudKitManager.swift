//
//  CloudKitManager.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 24/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import CloudKit

class CloudKitManager: DatabaseManager {
    
    // MARK: Singleton
    static let shared = CloudKitManager()
    
    // MARK: Variables
    let logger = ConsoleDebugLogger.shared
    
    // MARK: iCloud Variables
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

    // MARK: Initializers
    private init() {}
    
    // MARK: - CloudKit Record Manipulations
    fileprivate func persistRecord(_ record: CKRecord) {
        privateDB.save(record) { (savedRecord, error) in
            if error == nil {
                self.logger.log(message: "Record saved")
            } else {
                self.logger.log(message: "Record not  saved")
            }
        }
    }
    
    fileprivate func createCoinRecord() {
        // If it doesn't, create it and return 0
        let coinCount = 0
        
        let record = CKRecord(recordType: "Coin")
        record.setValue(coinCount, forKey: "amount")

        logger.log(message: "Persisting \(record)")
        
        persistRecord(record)
    }
    
    private func retrieveCoinRecord(_ callback: @escaping (CKRecord?) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Coin", predicate: predicate)

        logger.log(message: " Performing query...")
        privateDB.fetch(
            withQuery: query,
            inZoneWith: CKRecordZone.default().zoneID,
            desiredKeys: nil,
            resultsLimit: 1
        ) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                let firstRecord = response.matchResults.compactMap { try? $0.1.get() }.first
                callback(firstRecord)
            case .failure(let error):
                self.logger.log(message: "Error: \(error.localizedDescription)")
            }
        }
    }
    
    fileprivate func createMatchHistoryRecord(hash: String, coinsAwarded: Int) {
        
        let record = CKRecord(recordType: "MatchHistory")
        record.setValue(coinsAwarded, forKey: "coinsAwarded")
        record.setValue(hash, forKey: "matchHash")
        
        logger.log(message: "Persisting \(record)")
        
        persistRecord(record)
    }
    
    private func retrieveMatchHistoryRecord(withHash hash: String, _ callback: @escaping (CKRecord?) -> Void) {
        let predicate = NSPredicate(format: "matchHash == %@", hash)
        let query = CKQuery(recordType: "MatchHistory", predicate: predicate)

        logger.log(message: "Performing query...")
        privateDB.fetch(
            withQuery: query,
            inZoneWith: CKRecordZone.default().zoneID,
            desiredKeys: nil,
            resultsLimit: 1
        ) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                let firstRecord = response.matchResults.compactMap { try? $0.1.get() }.first
                callback(firstRecord)
            case .failure(let error):
                self.logger.log(message: "Error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: DatabaseManager Methods
    func checkMatchExists(hash: String, _ callback: @escaping (Bool) -> Void) {
        guard Self.isAvailable else { callback(false); return }
        // Check if it exists in the remote container
        retrieveMatchHistoryRecord(withHash: hash) { (matchRecord) in
            if matchRecord != nil {
                // If it does, return true
                self.logger.log(message: "Match \(hash) found!")
                callback(true)
            } else {
                // If it doesn't, return false
                self.logger.log(message: "Match \(hash) not found")
                callback(false)
            }
        }
        
    }
    
    func addNewMatch(withHash hash: String, coinCount: Int) {
        guard Self.isAvailable else { return }
        logger.log(message: "Attempting to add match with hash \(hash)")
        checkMatchExists(hash: hash, { (result) in
            // doesn't exists
            if !result {
                // Add to database
                self.logger.log(message: "Match doesn't exist! Great :). Creating record...")
                self.createMatchHistoryRecord(hash: hash, coinsAwarded: coinCount)
                
                // update coin count
                self.logger.log(message: "Updating coin count.")
                self.getPlayerCoinCount {
                    self.setPlayerCoinCount(toValue: $0 + coinCount)
                }
            }
        })
        //
            
    }
    
    func getPlayerCoinCount(_ callback: @escaping (Int) -> Void) {
        guard Self.isAvailable else { callback(0); return }
        // If it does, return count

        // Fetch first record and see if it exists
        retrieveCoinRecord { coinRecord in
            if let record = coinRecord {
                self.logger.log(message: "Fetch success")
                let amount = record["amount"] as! Int
                
                self.logger.log(message: "Returning amount as \(amount)")
                callback(amount)
            } else {
                self.logger.log(message: "Creating coin record")
                self.createCoinRecord()
                callback(0)
            }
        }
        
    }
    
    func setPlayerCoinCount(toValue value: Int) {
        guard Self.isAvailable else { return }
        // Check if it exists
        retrieveCoinRecord { coinRecord in
            if let record = coinRecord {
                // If it does, update it's value
                record.setValue(value, forKey: "amount")
                self.persistRecord(record)
            } else {
                self.createCoinRecord()
            }
        }
        
    }
    
}
