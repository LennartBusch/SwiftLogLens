# SwiftLogLens

SwiftLogLens is a wrapper around Apple Unified Logging with a macro-first API.

Since `2.0`, the recommended logging entry point is `#loglens(...)`:
- clickable call-sites in Xcode console
- low overhead runtime path
- optional in-memory / on-disk mirroring for later inspection

## Why this package exists

SwiftLogLens exists to make Unified Logging more practical inside apps at runtime.

- On iOS/watchOS, reading logs during runtime is more limited than on macOS.
- On watchOS in particular, log retrieval can require extra setup/profiles during development.
- App-side debugging often needs an in-app log viewer and optional persistence, not only external Console tools.

`#loglens(...)` keeps OS logging as the source of truth while optionally mirroring entries to memory/disk when you need reliable in-app inspection.

## Setup

`LogCategory` is optional.

- If you define a `LogCategory` enum, filtering/display in `LogLensView` is easier and strongly typed.
- If you skip it, you can still use `#loglens(...)` with string categories (or automatic default categories).

### Optional typed categories (`LogCategory`)

```swift
import SwiftLogLens

enum Logs: String, LogCategory {
    var id: Self { self }
    case network
    case ui
    case networkUtil
}
```

### Without typed categories

```swift
import SwiftLogLens

#loglens("Boot finished")
#loglens(category: "network", .info, "Request started")
```

## Recommended logging (`2.0+`)

### Basic

```swift
#loglens("View appeared")
#loglens(.error, "Network request failed")
#loglens(category: "network", .debug, "Request started")
```

### Privacy

```swift
#loglens("Fetched token \(token)", privacy: .private)
#loglens("Auth date \(Date())", privacy: .sensitive)
```

### Default category resolution

If `category:` is not passed, LogLens resolves category in this order:
1. `@LoglensCategrory(...)` / `@LoglensCategory(...)` on enclosing type
2. Enclosing type name (`class` / `struct` / `actor` / `enum`)
3. File name (without `.swift`)

```swift
@LoglensCategory(Logs.networkUtil)
final class NetworkUtil {
    func fetch() {
        #loglens("Request started") // category: "networkUtil"
    }
}
```

If you want stronger autocomplete for cases, use the typed overload:

```swift
typealias AppLogs = Logs

@LoglensCategory(AppLogs.self, .networkUtil)
final class NetworkUtil {
    func fetch() {
        #loglens("Request started")
    }
}
```

## Config

```swift
// Unified log subsystem (defaults to bundle identifier)
LogLensConfig.setSubsystem("com.mycompany.myapp")

// Optional mirrors
LogLensConfig.storeInMemory(true)
LogLensConfig.storeOnDisk(true)

// Optional app group for shared file location
LogLensConfig.setAppGroup("group.com.mycompany.myapp")
```

## Viewing logs in-app

`LogLensView` fetches logs from `OSLogStore` and displays them.

```swift
NavigationStack {
    LogLensView(categoryType: Logs.self)
}
```

## Disk log file access

```swift
// MainActor property
let url = LogStore.logURL
```

Prune old persisted entries:

```swift
await LogLens.store.pruneLogs(olderThanDays: 5)
```

## Legacy API (before `2.0`)

Before `2.0`, logging was mainly done through `LogLens(category:)` + `osLogger` / `log(...)`.
This is still supported for compatibility, but no longer recommended.

```swift
let lens = LogLens(category: Logs.network)
let logger = lens.osLogger

logger.log("Message")
lens.log(level: .error, "Fallback wrapper log")
```

Use `#loglens(...)` for new code.
