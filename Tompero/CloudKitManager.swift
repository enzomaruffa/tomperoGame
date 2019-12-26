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
                print("[CloudKitManager.persistRecord] Record Saved")
            } else {
                print("[CloudKitManager.persistRecord] Record Not Saved")
            }
        }
    }
    
    fileprivate func createCoinRecord() {
        // If it doesn't, create it and return 0
        let coinCount = 0
        
        let record = CKRecord(recordType: "Coin")
        record.setValue(coinCount, forKey: "amount")
        
        print("[CloudKitManager.createCoinRecord] Persisting \(record)")
        
        persistRecord(record)
    }
    
    private func retrieveCoinRecord(_ callback: @escaping (CKRecord?) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Coin", predicate: predicate)
        
        var firstResult: CKRecord?
        
        print("[CloudKitManager.retrieveCoinRecord] Performing query...")
        privateDB.perform(query,
                          inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                            print("[CloudKitManager.retrieveCoinRecord] Query in progress")
                            guard let self = self else {
                                print("[CloudKitManager.retrieveCoinRecord] Self is nil, oops")
                                return }
                            
                            if let error = error {
                                print("[CloudKitManager.retrieveCoinRecord] Error found!")
                                return
                            }
                            
                            // Check if it exists in the remote container
                            guard let results = results else {
                                print("[CloudKitManager.retrieveCoinRecord] Returning nil!")
                                callback(nil)
                                return
                            }
                            print("[CloudKitManager.retrieveCoinRecord] First result found :)")
                            firstResult = results.first
                            callback(firstResult)
        }
    }
    
    // MARK: DatabaseManager Methods
    func checkMatchExists(hash: String, _ callback: @escaping (Bool) -> Void) {
        // Check if it exists in the remote container
        // If it does, return true
        // If it doesn't, return false
        
    }
    
    func addNewMatch(withHash hash: String, coinCount: Int) {
        checkMatchExists(hash: hash, { (result) in
            // doesn't exists
            if !result {
                // Add to database
                
                // update coin count
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
                print("[CloudKitManager.playerCoinCount.get] Fetch success")
                let amount = record["amount"] as! Int
                
                print("[CloudKitManager.playerCoinCount.get] Returning amount as \(amount)")
                callback(amount)
            } else {
                print("[CloudKitManager.playerCoinCount.get] Creating coin record")
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