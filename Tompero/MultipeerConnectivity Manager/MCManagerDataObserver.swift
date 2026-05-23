//
//  MCManagerObserver.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

protocol MCManagerDataObserver: AnyObject {

    func receiveData(wrapper: MCDataWrapper)

}
