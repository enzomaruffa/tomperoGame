//
//  Logger.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 26/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

protocol DebugLogger {
    func log(file: String, line: Int, function: String, message: String)
}
