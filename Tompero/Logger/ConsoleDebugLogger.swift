//
//  ConsoleDebugLogger.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 26/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation

class ConsoleDebugLogger: DebugLogger {
    
    static let shared = ConsoleDebugLogger()
    
    let formatter: DateFormatter
    
    private init() {
        formatter = DateFormatter()
        formatter.dateFormat = "y/MM/dd H:m:ss.SSSS"
    }
    
    func log(file: String = #file, line: Int = #line, function: String = #function, message: String) {
        
        let fileName = file.split(separator: "/").last!.split(separator: ".").first!
        
        let functionName = function.split(separator: "(").first!
        
        print("[\(formatter.string(from: Date())) \(fileName).\(functionName) (\(line))]: \(message)")
    }
    
}
