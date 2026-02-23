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
    
    private enum Key {
        static let storeCopy = "storeCopy"
        static let writeToDisk = "writeToDisk"
        static let subsystem = "subsystem"
        static let appGroup = "appGroup"
    }
    
    private static let lock = NSLock()
    
    private nonisolated(unsafe) static var cachedStoreCopyOnWrite: Bool = UserDefaults(suiteName: "loglens")?.bool(forKey: Key.storeCopy) ?? false
    private nonisolated(unsafe) static var cachedWriteToDisk: Bool = UserDefaults(suiteName: "loglens")?.bool(forKey: Key.writeToDisk) ?? false
    private nonisolated(unsafe) static var cachedDefaultSubsystem: String = UserDefaults(suiteName: "loglens")?.string(forKey: Key.subsystem) ?? (Bundle.main.bundleIdentifier ?? "LogLens")
    private nonisolated(unsafe) static var cachedAppGroup: String? = UserDefaults(suiteName: "loglens")?.string(forKey: Key.appGroup)
    
    
    /// Setting if a copy of the log should be stored in memory
    /// Only valid if LogLens.log() is used
    static var storeCopyOnWrite: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cachedStoreCopyOnWrite
    }
    
    /// Setting if a copy of the log should be directly written to disk
    /// Only valid if LogLens.log() is used
    static var writeToDisk: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cachedWriteToDisk
    }
    
    
    /// The defaults subsystem loglens writes to
    public static var defaultSubSystem: String {
        lock.lock()
        defer { lock.unlock() }
        return cachedDefaultSubsystem
    }
    
    /// The defaults subsystem loglens writes to
    static var appGroup: String?{
        lock.lock()
        defer { lock.unlock() }
        return cachedAppGroup
    }
    
    public static func storeOnDisk(_ value: Bool){
        lock.lock()
        cachedWriteToDisk = value
        lock.unlock()
        UserDefaults(suiteName: "loglens")?.set(value, forKey: Key.writeToDisk)
    }
    
    public static func storeInMemory(_ value: Bool){
        lock.lock()
        cachedStoreCopyOnWrite = value
        lock.unlock()
        UserDefaults(suiteName: "loglens")?.set(value, forKey: Key.storeCopy)
    }
    
    public static func setSubsystem(_ subsystem: String){
        lock.lock()
        cachedDefaultSubsystem = subsystem
        lock.unlock()
        UserDefaults(suiteName: "loglens")?.set(subsystem, forKey: Key.subsystem)
        LogLens.updateSubsystem(subsystem)
    }
 
    public static func setAppGroup(_ appGroup: String){
        lock.lock()
        cachedAppGroup = appGroup
        lock.unlock()
        UserDefaults(suiteName: "loglens")?.set(appGroup, forKey: Key.appGroup)
    }
    
}
