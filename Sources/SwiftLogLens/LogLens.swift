import Foundation
@_exported import OSLog
import SwiftUI

public typealias CustomLog = (timestamp: Date, category: String, type: OSLogType, message: String)

private struct LoggerKey: Hashable {
    let subsystem: String
    let category: String
}

public struct LogLens: Sendable{
    
    public let osLogger: Logger
    let categoryName: String
    
    public static let store = LogStore.shared
    private static let loggerCacheLock = NSLock()
    private nonisolated(unsafe) static var loggerCache: [LoggerKey: Logger] = [:]
    
    public init(category: (any LogCategory)?){
        let categoryName = category?.rawValue ?? ""
        osLogger = LogLens.logger(forCategory: categoryName)
        self.categoryName = categoryName
    }
    
    public init(category: String?){
        let categoryName = category ?? ""
        osLogger = LogLens.logger(forCategory: categoryName)
        self.categoryName = categoryName
    }
    
    /// Logs a message
    /// - Parameters:
    ///   - level: The level of the logmessage
    ///   - message: The mesage
    ///
    ///   LogLens log function has no option for privacy redaction. All arguments will printed to the logstore in plaintext
    public func log(level: OSLogType = .default, _ message: String, _ privacy: OSLogPrivacy = .public){
        _ = privacy
        osLogger.log(level: level, "\(message, privacy: .public)")
        LogLens.persistIfConfigured(category: categoryName, level: level, message: message)
    }
    
    public static func logger(forCategory category: String) -> Logger {
        let normalizedCategory = category.isEmpty ? "LogLens" : category
        let key = LoggerKey(subsystem: LogLensConfig.defaultSubSystem, category: normalizedCategory)
        
        loggerCacheLock.lock()
        defer { loggerCacheLock.unlock() }
        
        if let cached = loggerCache[key] {
            return cached
        }
        
        let logger = Logger(subsystem: key.subsystem, category: key.category)
        loggerCache[key] = logger
        return logger
    }
    
    public static func defaultCategory(from fileID: StaticString) -> String {
        let fileIDString = String(describing: fileID)
        return defaultCategory(fromFilePath: fileIDString)
    }
    
    public static func defaultCategory(fromFilePath filePath: String) -> String {
        guard let lastPathComponent = filePath.split(separator: "/").last else {
            return "LogLens"
        }
        
        let fileName = String(lastPathComponent)
        guard let lastDot = fileName.lastIndex(of: ".") else {
            return fileName.isEmpty ? "LogLens" : fileName
        }
        
        let stem = String(fileName[..<lastDot])
        return stem.isEmpty ? "LogLens" : stem
    }
    
    public static func persistIfConfigured(category: String, level: OSLogType, message: String) {
        let storeInMemory = LogLensConfig.storeCopyOnWrite
        let writeToDisk = LogLensConfig.writeToDisk
        
        guard storeInMemory || writeToDisk else {
            return
        }
        
        let log: CustomLog = (timestamp: Date(), category: category, type: level, message: message)
        
        if storeInMemory {
            Task {
                await LogLens.store.addLog(log)
            }
        }
        
        if writeToDisk {
            Task {
                await LogLens.store.writeLog(log)
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
