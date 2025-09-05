//
//  LogStore.swift
//  SwiftLogLens
//
//  Created by Lennart Busch on 05.09.25.
//
import Foundation

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
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appending(path: "logLenslogs.csv")
    }()
    
    var logURL: URL?  = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appending(path: "logLenslogs.csv")
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

