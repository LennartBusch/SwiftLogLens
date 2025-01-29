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
    public static var storeCopyOnWrite: Bool = false
    
    /// The defaults subsystem loglens writes to
    public static var defaultSubSystem: String = Bundle.main.bundleIdentifier ?? "LogLens"
    
    
#if os(macOS)
    public static var storeScope: OSLogStore.Scope = .system
#else
    public static var storeScope: OSLogStore.Scope = .currentProcessIdentifier
#endif
    
    
}
