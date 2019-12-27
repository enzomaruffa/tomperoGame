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
    let container: CKContainer
    let publicDB: CKDatabase
    let privateDB: CKDatabase
    
    // MARK: Initializers
    private init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }
    
    
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
        
        var firstResult: CKRecord?
        
        logger.log(message: " Performing query...")
        privateDB.perform(query,
                          inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                            self?.logger.log(message: "Query in progress")
                            guard let self = self else { return }
                            
                            if let error = error {
                                self.logger.log(message: "Error: \(error.localizedDescription)")
                                return
                            }
                            
                            // Check if it exists in the remote container
                            guard let results = results else {
                                self.logger.log(message: "Returning nil!")
                                callback(nil)
                                return
                            }
                            self.logger.log(message: "First result found :)")
                            firstResult = results.first
                            callback(firstResult)
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
        
        var firstResult: CKRecord?
        
        logger.log(message: "Performing query...")
        privateDB.perform(query,
                          inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                            self?.logger.log(message: "Query in progress")
                            guard let self = self else { return }
                            
                            if let error = error {
                                self.logger.log(message: "Error: \(error.localizedDescription)")
                                return
                            }
                            
                            // Check if it exists in the remote container
                            guard let results = results else {
                                self.logger.log(message: "Returning nil!")
                                callback(nil)
                                return
                            }
                            self.logger.log(message: "First result found :)")
                            firstResult = results.first
                            callback(firstResult)
        }
    }
    
    // MARK: DatabaseManager Methods
    func checkMatchExists(hash: String, _ callback: @escaping (Bool) -> Void) {
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
