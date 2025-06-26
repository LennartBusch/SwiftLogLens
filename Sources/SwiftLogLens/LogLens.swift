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
    public func log(level: OSLogType = .default, _ message: String){
        osLogger.log(level: level, "\(message)")
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
        guard let store = try? OSLogStore(scope: LogLensConfig.storeScope) else {return []}
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



public actor LogStore{
    
    private init(){
        if let path = logURL , !FileManager.default.fileExists(atPath: path.path()){
            let string = "date;subsystem;type;message\n"
            try?  string.appendToURL(fileURL: path)
        }
    }
    static let shared = LogStore()
    
    var logs : [CustomLog] = []
    
    @MainActor
    public static var logURL: URL?  = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appending(path: "logs.csv")
    }()
    
    var logURL: URL?  = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appending(path: "logs.csv")
    }()
    
    
    func addLog(_ log: CustomLog){
        logs.append(log)
    }
    
    func writeLog(_ log: CustomLog){
        if let logURL{
            try? "\(log.timestamp.logFormat());\(log.category.rawValue.uppercased());\(log.type.levelDescription);\(log.message)\n".appendToURL(fileURL: logURL)
        }
    }
        
    /// Removes all persisted log entries that are older than the given number of days.
    /// - Parameter days: The amount of history (in days) to keep.
    public func pruneLogs(olderThanDays days: Int) {
        guard days > 0 else { return }
        
        // Calculate the cut‑off date.
        let thresholdDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        guard
            let fileURL = logURL,
            FileManager.default.fileExists(atPath: fileURL.path())
        else { return }
        
        guard
            let data = try? Data(contentsOf: fileURL),
            let csv = String(data: data, encoding: .utf8)
        else { return }
        
        // Split into header + body lines.
        var lines = csv.components(separatedBy: .newlines)
        guard !lines.isEmpty else { return }
        let header = lines.removeFirst()
        
        let formatter = DateFormatter()
        formatter.timeZone = .current
        formatter.dateFormat = "y-MM-dd, HH:mm:ss.SSSS"
        
        // Keep only lines whose timestamp is **after** the threshold.
        let kept = lines.filter { line in
            guard !line.isEmpty else { return false }        // skip blank lines
            let dateString = line.prefix { $0 != ";" }       // substring before the first ';'
            guard let date = formatter.date(from: String(dateString)) else {
                return true                                  // keep line if we can't parse date
            }
            return date >= thresholdDate
        }
        
        let newContent = ([header] + kept).joined(separator: "\n") + "\n"
        try? newContent.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}


struct Custom{
    var timestamp: Date
    var category: any LogCategory
    var type: OSLogType
    var message: String
}
