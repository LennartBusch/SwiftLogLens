import OSLog
import SwiftLogLens

@freestanding(expression)
public macro loglens(_ message: String, privacy: OSLogPrivacy = .public) = #externalMacro(
    module: "SwiftLogLensCompilerPlugin",
    type: "LogLensMacro"
)

@freestanding(expression)
public macro loglens(_ level: OSLogType, _ message: String, privacy: OSLogPrivacy = .public) = #externalMacro(
    module: "SwiftLogLensCompilerPlugin",
    type: "LogLensMacro"
)

@freestanding(expression)
public macro loglens(category: String, _ message: String, privacy: OSLogPrivacy = .public) = #externalMacro(
    module: "SwiftLogLensCompilerPlugin",
    type: "LogLensMacro"
)

@freestanding(expression)
public macro loglens(category: String, _ level: OSLogType, _ message: String, privacy: OSLogPrivacy = .public) = #externalMacro(
    module: "SwiftLogLensCompilerPlugin",
    type: "LogLensMacro"
)

@attached(member, names: named(__loglensDeclaredCategory))
@attached(extension, conformances: LogLensCategoryProviding)
public macro LoglensCategory(_ category: any LogCategory) = #externalMacro(
    module: "SwiftLogLensCompilerPlugin",
    type: "LogLensCategoryMacro"
)
