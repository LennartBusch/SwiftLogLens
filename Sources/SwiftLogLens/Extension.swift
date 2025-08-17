//
//  File.swift
//  EventLogger
//
//  Created by Lennart Busch on 31.12.24.
//

import Foundation
import OSLog
import SwiftUI

extension Date{
    func logFormat()->String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy/MM/dd HH:mm:ss.SSSS"
        return dateFormatter.string(from: self)
    }
}

extension OSLogEntry{
    
    public var levelColor: Color{
        guard let log = self as? OSLogEntryLog else {return .clear}
        switch log.level{
        case .undefined, .debug:
            return Color.clear
        case .info:
            return  Color.blue
        case .notice:
            return Color.yellow
        case .error, .fault:
            return Color.red
        @unknown default:
            return .clear
        }
    }
    
    public var type: OSLogType{
        guard let log = self as? OSLogEntryLog else {return .default}
        switch log.level{
        case .undefined:
            return .default
        case  .debug:
            return .debug
        case .info, .notice:
            return .info
        case .error:
            return .error
        case .fault:
            return .fault
        @unknown default:
            return .default
        }
    }
    
    public var categoryString: String{
        guard let log = self as? OSLogEntryLog else {return ""}
        return log.category
    }
    
    public var levelDescription: String{
        guard let log = self as? OSLogEntryLog else {return ""}
        return switch log.level{
        case .undefined:
            "undefined"
        case .debug:
            "debug"
        case .info:
            "info"
        case .notice:
            "notice"
        case .error:
            "error"
        case .fault:
            "fault"
        @unknown default:
            "unknown"
        }
    }
    
    func toCustomLog(type: any LogCategory.Type)->CustomLog?{
        if let category = type.init(rawValue: self.categoryString){
            return (timestamp: self.date,category: category,type: self.type, message: self.composedMessage)
        }
        return nil        
    }
}

extension OSLogType{
    
    var color: Color{
        switch self{
        case .debug: return .clear
        case .default: return .clear
        case .error, .fault : return .red
        case .info : return .clear
        default:
            return .clear
        }
    }
    
    var levelDescription: String{
        return switch self{
        case .debug:
            "debug"
        case .info:
            "info"
        case .info:
            "info"
        case .error:
            "error"
        case .fault:
            "fault"
        default:
            "default"
        }
    }
}


extension String {
    func appendLineToURL(fileURL: URL) throws {
         try (self + "\n").appendToURL(fileURL: fileURL)
     }
     
     func appendToURL(fileURL: URL) throws {
         let data = self.data(using: String.Encoding.utf8)!
         try data.append(fileURL: fileURL)
     }
 }

 extension Data {
     func append(fileURL: URL) throws {
         if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
             defer {
                 fileHandle.closeFile()
             }
             fileHandle.seekToEndOfFile()
             fileHandle.write(self)
         }
         else {
             try write(to: fileURL, options: .atomic)
         }
     }
 }
