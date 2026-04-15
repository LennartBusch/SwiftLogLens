import Foundation
@_exported import OSLog
import SwiftUI

private struct LoggerKey: Hashable {
    let subsystem: String
    let category: String
}

public protocol LogLensCategoryProviding {
    nonisolated static var __loglensDeclaredCategory: String { get }
}

public protocol LogLensLogging {}

public extension LogLensLogging {
    static var log: LogLens {
        LogLens(for: Self.self)
    }
    var log: LogLens {
        LogLens(for: Self.self)
    }

    static var osLogger: Logger {
        LogLens.osLogger(for: Self.self)
    }
}

public struct LogLens: Sendable {
    public let osLogger: Logger
    public let category: String

    public static let store = LogStore.shared
    private static let loggerCacheLock = NSLock()
    private nonisolated(unsafe) static var loggerCache: [LoggerKey: Logger] = [:]
    private nonisolated(unsafe) static var cachedSubsystem: String = LogLensConfig.defaultSubSystem

    public init(category: (any LogCategory)?) {
        self.init(category: category?.rawValue)
    }

    public init(category: String?) {
        let category = Self.normalizedCategory(category ?? "")
        osLogger = Self.logger(forCategory: category)
        self.category = category
    }

    public init(for type: Any.Type) {
        self.init(category: Self.category(forContextType: type))
    }

    public init(fileID: StaticString = #fileID) {
        self.init(category: Self.defaultCategory(from: fileID))
    }

    public static func logger(_ category: any LogCategory) -> LogLens {
        LogLens(category: category)
    }

    public static func logger(_ category: String) -> LogLens {
        LogLens(category: category)
    }

    public static func logger(for type: Any.Type) -> LogLens {
        LogLens(for: type)
    }

    public static func logger(fileID: StaticString = #fileID) -> LogLens {
        LogLens(fileID: fileID)
    }

    public static func osLogger(_ category: any LogCategory) -> Logger {
        logger(forCategory: category.rawValue)
    }

    public static func osLogger(_ category: String) -> Logger {
        logger(forCategory: category)
    }

    public static func osLogger(for type: Any.Type) -> Logger {
        logger(forCategory: category(forContextType: type))
    }

    public static func osLogger(fileID: StaticString = #fileID) -> Logger {
        logger(forCategory: defaultCategory(from: fileID))
    }

    public func callAsFunction(_ message: @autoclosure () -> String) {
        log(message())
    }

    public func callAsFunction(level: OSLogType = .default, _ message: @autoclosure () -> String) {
        log(level: level, message())
    }

    public func log(_ message: @autoclosure () -> String) {
        log(level: .default, message())
    }

    public func debug(_ message: @autoclosure () -> String) {
        log(level: .debug, message())
    }

    public func info(_ message: @autoclosure () -> String) {
        log(level: .info, message())
    }

    public func error(_ message: @autoclosure () -> String) {
        log(level: .error, message())
    }

    public func fault(_ message: @autoclosure () -> String) {
        log(level: .fault, message())
    }

    /// Logs a message and mirrors it into LogLens storage if configured.
    /// - Note: The `privacy` argument is retained for compatibility. String-based logging
    ///   always writes the mirrored message in plain text when persistence is enabled.
    public func log(level: OSLogType = .default, _ message: String, _ privacy: OSLogPrivacy = .public) {
        _ = privacy
        osLogger.log(level: level, "\(message, privacy: .public)")
        Self.persistIfConfigured(category: category, level: level, message: message)
    }

    public static func logger(forCategory category: String) -> Logger {
        let normalizedCategory = normalizedCategory(category)

        loggerCacheLock.lock()
        defer { loggerCacheLock.unlock() }

        let key = LoggerKey(subsystem: cachedSubsystem, category: normalizedCategory)

        if let cached = loggerCache[key] {
            return cached
        }

        let logger = Logger(subsystem: key.subsystem, category: key.category)
        loggerCache[key] = logger
        return logger
    }

    public static func updateSubsystem(_ subsystem: String) {
        loggerCacheLock.lock()
        cachedSubsystem = subsystem
        loggerCache.removeAll(keepingCapacity: true)
        loggerCacheLock.unlock()
    }

    public static func defaultCategory(from fileID: StaticString) -> String {
        defaultCategory(fromFilePath: String(describing: fileID))
    }

    public static func category(forContextType type: Any.Type) -> String {
        if let categoryProvider = type as? LogLensCategoryProviding.Type {
            return normalizedCategory(categoryProvider.__loglensDeclaredCategory)
        }
        return defaultCategory(fromType: type)
    }

    public static func defaultCategory(fromType type: Any.Type) -> String {
        let typeName = String(reflecting: type)
        guard let leafTypeName = typeName.split(separator: ".").last else {
            return "LogLens"
        }

        return normalizedCategory(String(leafTypeName))
    }

    public static func defaultCategory(fromFilePath filePath: String) -> String {
        guard let lastPathComponent = filePath.split(separator: "/").last else {
            return "LogLens"
        }

        let fileName = String(lastPathComponent)
        guard let lastDot = fileName.lastIndex(of: ".") else {
            return normalizedCategory(fileName)
        }

        return normalizedCategory(String(fileName[..<lastDot]))
    }

    public static func persistIfConfigured(category: String, level: OSLogType, message: String) {
        let storeInMemory = LogLensConfig.storeCopyOnWrite
        let writeToDisk = LogLensConfig.writeToDisk

        guard storeInMemory || writeToDisk else {
            return
        }

        let log = CustomLog(timestamp: Date(), category: normalizedCategory(category), type: level, message: message)
        Task {
            await LogLens.store.append(log, storeInMemory: storeInMemory, writeToDisk: writeToDisk)
        }
    }

    public static var shouldPersistLogs: Bool {
        LogLensConfig.storeCopyOnWrite || LogLensConfig.writeToDisk
    }

    static func loadLogs(
        _ category: (any LogCategory)? = nil,
        since fetchDate: Date = Date().addingTimeInterval(-1 * 60 * 60 * 24)
    ) -> [OSLogEntry] {
        guard let store = try? OSLogStore(scope: .currentProcessIdentifier) else {
            return []
        }

        let predicate: NSPredicate
        if let category {
            predicate = NSPredicate(
                format: "(subsystem == %@) && (category IN %@)",
                LogLensConfig.defaultSubSystem,
                [category.rawValue]
            )
        } else {
            predicate = NSPredicate(format: "subsystem == %@", LogLensConfig.defaultSubSystem)
        }

        let pos = store.position(date: fetchDate)
        return (try? store.getEntries(at: pos, matching: predicate).compactMap { $0 }) ?? []
    }

    private static func normalizedCategory(_ category: String) -> String {
        let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "LogLens" : trimmed
    }
}
