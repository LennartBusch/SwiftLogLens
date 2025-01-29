//
//  ViewModel.swift
//  SwiftLogLens
//
//  Created by Lennart Busch on 19.01.25.
//

import Foundation
import OSLog

extension LogLensView{
    
    @MainActor
    class ViewModel: ObservableObject{
        
        @Published var logs: [OSLogEntry] = []
        @Published var fetching: Bool = false
        @MainActor
        var customLogs: [CustomLog] {
            LogLens.logs
        }
        
        /// Loads the logs from the logstore
        /// - Parameter category: The category of logs that should be loaded
        ///
        /// By default this method loads all logs of the default subsystem
        func loadLogs(_ category: (any LogCategory)? = nil){
            let pastDay: Double = -1 * 60 * 60 * 24
            fetching = true
            DispatchQueue.global(qos: .utility).async {
                guard let store = try? OSLogStore(scope: LogLensConfig.storeScope) else {return}
                var predicate: NSPredicate
                if let category{
                    predicate = NSPredicate(format: "(subsystem == %@) && (category IN %@)", LogLensConfig.defaultSubSystem, [category.rawValue])
                }
                else{
                    predicate = NSPredicate(format: "subsystem == %@", LogLensConfig.defaultSubSystem)
                }
                let pos = store.position(date: Date().addingTimeInterval(pastDay))
                let osLogs = (try? store.getEntries(at: pos, matching: predicate).compactMap({$0})) ?? []
                DispatchQueue.main.async {
                    self.logs = osLogs
                    self.fetching = false
                }
            }
        }
    }
}
