//
//  File.swift
//  SwiftLogLens
//
//  Created by Lennart Busch on 23.02.26.
//

import Foundation
import OSLog

public struct CustomLog: Sendable{
    var timestamp: Date
    var category: String
    var type: OSLogType
    var message: String
}
