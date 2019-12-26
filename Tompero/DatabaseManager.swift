//
//  DatabaseManager.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 24/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

protocol DatabaseManager {
    func getPlayerCoinCount(_ callback:  @escaping (Int) -> Void)
    func setPlayerCoinCount(toValue value: Int)
    
    func checkMatchExists(hash: String, _ callback: @escaping (Bool) -> Void)
    func addNewMatch(withHash hash: String, coinCount: Int)
}
