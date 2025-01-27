// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import OSLog
import SwiftUI

typealias CustomLog = (timestamp: Date,category: any LogCategory,type: OSLogType,message: String)

public struct LogLens{
    
    public let osLogger: Logger
    let category: any LogCategory
    
    @MainActor static var logs: [CustomLog] = []
    

    public init(category: any LogCategory){
        osLogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: category.rawValue)
        self.category = category
    }
    
    public func log(level: OSLogType = .default, _ message: String){
        osLogger.log(level: level, "\(message)")
        let date = Date()
        DispatchQueue.main.async {[category] in
            LogLens.logs.append((date, category, level, message))
        }
    }
}



