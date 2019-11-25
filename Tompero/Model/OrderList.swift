//
//  OrderList.swift
//  Tompero
//
//  Created by Vinícius Binder on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class OrderList {
    var orders = [Order]()
    
    func removeOrder(ofNumber index: Int) {
        orders.remove(at: index)
    }
}
