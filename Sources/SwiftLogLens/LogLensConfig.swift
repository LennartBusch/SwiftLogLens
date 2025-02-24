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
    static var storeCopyOnWrite: Bool = false
    
    /// The defaults subsystem loglens writes to
    static var defaultSubSystem: String = Bundle.main.bundleIdentifier ?? "LogLens"
    
    public static func setStoreOnWrite(_ value: Bool){
        LogLensConfig.storeCopyOnWrite = value
    }
    
    public static func setStore(_ scope: OSLogStore.Scope){
        LogLensConfig.storeScope = scope
    }
    
    public static func setSubsystem(_ subsystem: String){
        LogLensConfig.defaultSubSystem = subsystem
    }
    
#if os(macOS)
    public static var storeScope: OSLogStore.Scope = .system
#else
    public static var storeScope: OSLogStore.Scope = .currentProcessIdentifier
#endif
    
    
}
