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
        dateFormatter.dateFormat = "yy/MM/dd, HH:mm:ss.SSSS"
        return dateFormatter.string(from: self)
    }
}

extension OSLogEntry{
    
    var levelColor: Color{
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
    
    var type: OSLogType{
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
    
    var categoryString: String{
        guard let log = self as? OSLogEntryLog else {return ""}
        return log.category
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
}
