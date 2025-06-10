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
        if LogLensConfig.storeCopyOnWrite{
            let date = Date()
            Task{
                await LogLens.store.addLog((date, category, level, message))
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
    
    private init(){}
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
    
    public func save(){
        guard
            let fileURL = logURL,
            LogLensConfig.storeCopyOnWrite
        else { return }
        
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path())
        let fileSize = attributes?[FileAttributeKey.size] as? Int ?? 0
        var string = ""
        for log in logs{
            string += "\(log.timestamp.logFormat());\(log.category.rawValue.uppercased());\(log.type.levelDescription);\(log.message)\n"
        }
        if fileSize > 1024 * 5 || fileSize == 0{
            string = "date;subsystem;type;message\n" + string
            try? FileManager.default.removeItem(at: fileURL)
        }
        try? string.appendToURL(fileURL: fileURL)
    }
}


struct Custom{
    var timestamp: Date
    var category: any LogCategory
    var type: OSLogType
    var message: String
}

