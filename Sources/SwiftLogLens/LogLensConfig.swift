//
//  File.swift
//  SwiftLogLens
//
//  Created by Lennart Busch on 19.01.25.
//

import Foundation
import OSLog

public actor LogLensConfig {
    
    
    private init(){}
    
    
    /// Setting if a copy of the log should be stored in memory
    /// Only valid if LogLens.log() is used
    static var storeCopyOnWrite: Bool {
        return UserDefaults(suiteName: "loglens")?.bool(forKey: "storeCopy") ?? false
    }
    
    /// Setting if a copy of the log should be directly written to disk
    /// Only valid if LogLens.log() is used
    static var writeToDisk: Bool {
        return UserDefaults(suiteName: "loglens")?.bool(forKey: "writeToDisk") ?? false
    }
    
    
    /// The defaults subsystem loglens writes to
    public static var defaultSubSystem: String {
        return UserDefaults(suiteName: "loglens")?.string(forKey: "subsystem") ?? (Bundle.main.bundleIdentifier ?? "LogLens")
    }
    
    /// The defaults subsystem loglens writes to
    static var appGroup: String?{
        return UserDefaults(suiteName: "loglens")?.string(forKey: "appGroup")
    }
    
    public static func storeOnDisk(_ value: Bool){
        UserDefaults(suiteName: "loglens")?.set(value, forKey: "writeToDisk")
    }
    
    public static func storeInMemory(_ value: Bool){
        UserDefaults(suiteName: "loglens")?.set(value, forKey: "storeCopy")
    }
    
    public static func setSubsystem(_ subsystem: String){
        UserDefaults(suiteName: "loglens")?.set(subsystem, forKey: "subsystem")
    }
 
    public static func setAppGroup(_ appGroup: String){
        UserDefaults(suiteName: "loglens")?.set(appGroup, forKey: "appGroup")
    }
    
}
