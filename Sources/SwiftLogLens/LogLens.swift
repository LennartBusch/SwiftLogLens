import Foundation
import OSLog
import SwiftUI

typealias CustomLog = (timestamp: Date,category: any LogCategory,type: OSLogType,message: String)

public struct LogLens: Sendable{
    
    public let osLogger: Logger
    let category: any LogCategory
    
    public static let store = LogStore.shared
    
    public init(category: any LogCategory){
        osLogger = Logger(subsystem: LogLensConfig.defaultSubSystem, category: category.rawValue)
        self.category = category
    }
    
    /// Logs a message
    /// - Parameters:
    ///   - level: The level of the logmessage
    ///   - message: The mesage
    ///
    ///   LogLens log function has no option for privacy redaction. All arguments will printed to the logstore in plaintext
    public func log(level: OSLogType = .default, _ message: String, _ privacy: OSLogPrivacy = .public){
        osLogger.log(level: level, "\(message, privacy: .public)")
        let date = Date()
        if LogLensConfig.storeCopyOnWrite{
            Task{
                await LogLens.store.addLog((date, category, level, message))
            }
        }
        if LogLensConfig.writeToDisk{
            Task{
                await LogLens.store.writeLog((date, category, level, message))
            }
        }
    }
    
    static func loadLogs(
        _ category: (any LogCategory)? = nil,
        since fetchDate: Date = Date().addingTimeInterval(-1 * 60 * 60 * 24)
    )->[OSLogEntry]{
        guard let store = try? OSLogStore(scope: .currentProcessIdentifier) else {return []}
        var predicate: NSPredicate
        if let category{
            predicate = NSPredicate(format: "(subsystem == %@) && (category IN %@)", LogLensConfig.defaultSubSystem, [category.rawValue])
        }
        else{
            predicate = NSPredicate(format: "subsystem == %@", LogLensConfig.defaultSubSystem)
        }
        let pos = store.position(date: fetchDate)
        let osLogs = (try? store.getEntries(at: pos, matching: predicate).compactMap({$0})) ?? []
        return osLogs
        
    }
    
}



