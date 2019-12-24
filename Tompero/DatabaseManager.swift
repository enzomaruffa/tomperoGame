//
//  DatabaseManager.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 24/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

protocol DatabaseManager {
    var playerCoinCount: Int {get set}
    
    func checkMatchExists(hash: String) -> Bool
    func addNewMatch(withHash hash: String, coinCount: Int)
}
