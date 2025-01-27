//
//  File.swift
//  EventLogger
//
//  Created by Lennart Busch on 31.12.24.
//

import Foundation


public protocol LogCategory: Identifiable, CaseIterable, RawRepresentable<String>, Hashable, Sendable {}

