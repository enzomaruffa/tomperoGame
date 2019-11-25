//
//  MCDataWrapper.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 25/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class MCDataWrapper: Codable  {
    
    let object: Data
    let type: MCDataType
    
    init(object: Data, type: MCDataType) {
        self.object = object
        self.type = type
    }
    
    func dataType() -> NSObject.Type? {
        if type == .plate {
            //return plate type
        }
        return nil
    }
    
}
