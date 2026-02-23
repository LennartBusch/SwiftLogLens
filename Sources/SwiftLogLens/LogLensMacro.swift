import OSLog

@freestanding(expression)
public macro loglens(_ message: String, privacy: OSLogPrivacy = .public) = #externalMacro(
    module: "SwiftLogLensMacros",
    type: "LogLensMacro"
)

@freestanding(expression)
public macro loglens(_ level: OSLogType, _ message: String, privacy: OSLogPrivacy = .public) = #externalMacro(
    module: "SwiftLogLensMacros",
    type: "LogLensMacro"
)

@freestanding(expression)
public macro loglens(category: String, _ message: String, privacy: OSLogPrivacy = .public) = #externalMacro(
    module: "SwiftLogLensMacros",
    type: "LogLensMacro"
)

@freestanding(expression)
public macro loglens(category: String, _ level: OSLogType, _ message: String, privacy: OSLogPrivacy = .public) = #externalMacro(
    module: "SwiftLogLensMacros",
    type: "LogLensMacro"
)

@attached(member, names: named(__loglensDeclaredCategory))
public macro LoglensCategrory(_ category: any LogCategory) = #externalMacro(
    module: "SwiftLogLensMacros",
    type: "LogLensCategoryMacro"
)

@attached(member, names: named(__loglensDeclaredCategory))
public macro LoglensCategory(_ category: any LogCategory) = #externalMacro(
    module: "SwiftLogLensMacros",
    type: "LogLensCategoryMacro"
)
