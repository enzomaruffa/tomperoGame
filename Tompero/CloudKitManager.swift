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
    
    // MARK: Computed Properties
    
    var playerCoinCount: Int {
        get {
            var coins = 0
            
           // Fetch first record and see if it exists
            // If it does, return count
            if let coinRecord = retrieveCoinRecord() {
                let amount = coinRecord["amount"] as! Int
                coins = amount
            } else {
                createCoinRecord()
            }
                        
            return coins
        }
        set {
            // Check if it exists
            if let coinRecord = retrieveCoinRecord() {
                // If it does, update it's value
                coinRecord.setValue(newValue, forKey: "amount")
                persistRecord(coinRecord)
            } else {
               createCoinRecord()
            }
        }
    }
    
    // MARK: - CloudKit Record Manipulations
    fileprivate func persistRecord(_ record: CKRecord) {
        privateDB.save(record) { (savedRecord, error) in
            if error == nil {
                print("Record Saved")
            } else {
                print("Record Not Saved")
            }
        }
    }
    
    fileprivate func createCoinRecord() {
        // If it doesn't, create it and return 0
        let coinCount = 0
        
        let record = CKRecord(recordType: "Coin")
        record.setValue(coinCount, forKey: "amount")
        
        persistRecord(record)
    }
    
    private func retrieveCoinRecord() -> CKRecord? {

        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Coin", predicate: predicate)
        
        var firstResult: CKRecord?
        
        privateDB.perform(query,
                         inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                            guard let self = self else { return }
                            
                            if let error = error {
                                return
                            }

                            // Check if it exists in the remote container
                            guard let results = results else { return }
                            firstResult = results.first
        }
        
        return firstResult
    }
    
    // MARK: DatabaseManager Methods
    func checkMatchExists(hash: String) -> Bool {
        // Check if it exists in the remote container
        // If it does, return true
        // If it doesn't, return false
        
        return false
    }
    
    func addNewMatch(withHash hash: String, coinCount: Int) {
        if !checkMatchExists(hash: hash) {
            // Add to database
            // Update coin count
            playerCoinCount += coinCount
        }
        //
    }
    
    
}
