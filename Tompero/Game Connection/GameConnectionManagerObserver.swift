//
//  GameConnectionManagerObserver.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

protocol GameConnectionManagerObserver {
    
    // funcoes para receber ingredientes etc
    func receivePlate(plate: Plate)
    func receiveIngredient(ingredient: Ingredient)
    func receiveOrders(orders: [Order])
    func receiveDeliveryNotification(notification: OrderDeliveryNotification)
    func receiveStatistics(statistics: MatchStatistics)
    
}
