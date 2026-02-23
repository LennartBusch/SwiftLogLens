//
//  LogStore.swift
//  SwiftLogLens
//
//  Created by Lennart Busch on 05.09.25.
//
import Foundation

public actor LogStore{
    
    private init(){}
    
    deinit {
        persistentFileHandle?.closeFile()
    }
    
    static let shared = LogStore()
    
    var logs : [CustomLog] = []
    private var persistentFileHandle: FileHandle?
    private var persistentFileURL: URL?
    
    @MainActor
    public static var logURL: URL? {
        if let appgroup = LogLensConfig.appGroup {
            return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appgroup)?.appending(path: "logLenslogs.csv")
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appending(path: "logLenslogs.csv")
    }
    
    var logURL: URL? {
        if let appgroup = LogLensConfig.appGroup {
            return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appgroup)?.appending(path: "logLenslogs.csv")
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appending(path: "logLenslogs.csv")
    }
    
    
    func clearLogs(){
        logs.removeAll()
    }
    
    func append(_ log: CustomLog, storeInMemory: Bool, writeToDisk: Bool) {
        if storeInMemory {
            addLog(log)
        }
        
        if writeToDisk {
            writeLog(log)
        }
    }
    
    func addLog(_ log: CustomLog){
        logs.append(log)
    }
    
    func writeLog(_ log: CustomLog){
        guard let logURL else {
            return
        }
        
        guard let fileHandle = fileHandle(for: logURL) else {
            return
        }
        
        let line = "\(log.timestamp.logFormat());\(log.category.uppercased());\(log.type.levelDescription);\(log.message)\n"
        if let data = line.data(using: .utf8) {
            fileHandle.write(data)
        }
    }
    
    private func ensureLogFileExists(at path: URL) {
        if !FileManager.default.fileExists(atPath: path.path()) {
            let header = "date;category;type;message\n"
            try? header.appendToURL(fileURL: path)
        }
    }
    
    private func fileHandle(for url: URL) -> FileHandle? {
        if persistentFileURL != url {
            persistentFileHandle?.closeFile()
            persistentFileHandle = nil
            persistentFileURL = url
        }
        
        if let persistentFileHandle {
            return persistentFileHandle
        }
        
        ensureLogFileExists(at: url)
        
        guard let newHandle = try? FileHandle(forWritingTo: url) else {
            return nil
        }
        
        newHandle.seekToEndOfFile()
        persistentFileHandle = newHandle
        return newHandle
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
        formatter.dateFormat = "y-MM-dd HH:mm:ss.SSSS"
        
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
