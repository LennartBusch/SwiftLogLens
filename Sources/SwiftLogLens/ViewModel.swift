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
        
        func loadLogs(_ category: (any LogCategory)? = nil){
            let pastDay: Double = -1 * 60 * 60 * 24
            fetching = true
            DispatchQueue.global(qos: .utility).async {
                guard let store = try? OSLogStore(scope: .currentProcessIdentifier) else {return}
                var predicate: NSPredicate
                if let category{
                    predicate = NSPredicate(format: "(subsystem == %@) && (category IN %@)", Bundle.main.bundleIdentifier!, [category.rawValue])
                }
                else{
                    predicate = NSPredicate(format: "subsystem == %@", Bundle.main.bundleIdentifier!)
                }
                let pos = store.position(date: Date().addingTimeInterval(pastDay))
                let osLogs = (try? store.getEntries(at: pos, matching: predicate).compactMap({$0})) ?? []
                DispatchQueue.main.async {
                    self.logs = osLogs
                    self.fetching = false
                }
            }
        }
        
        private func addLogs(_ logs: [OSLogEntry]){
            self.logs = logs
        }
        
        
    }
}
