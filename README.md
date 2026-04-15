# SwiftLogLens

SwiftLogLens is a wrapper around Apple Unified Logging with an in-app viewer and optional log mirroring.

Since `2.1`, the package is split into two products:

- `SwiftLogLens`: core runtime product with no macro dependency
- `SwiftLogLensMacros`: optional macro product for `#loglens(...)` and `@LoglensCategory(...)`

Use the core product by default if you care about archive and incremental build speed.

## Why this package exists

SwiftLogLens makes Unified Logging easier to use inside apps while still keeping Apple's logging system as the source of truth.

- On iOS/watchOS, reading logs at runtime is more limited than on macOS.
- App-side debugging often needs an in-app log viewer and optional persistence.
- Many apps want ergonomic logging without pulling macros into every build.

## Optional typed categories

```swift
import SwiftLogLens

enum Logs: String, LogCategory {
    var id: Self { self }

    case network
    case ui
    case networkUtil
}
```

## Core logging

The core product is now the recommended entry point.

### File-based logger

```swift
import SwiftLogLens

private let log = LogLens.logger()

log("Boot finished")
log.info("Request started")
log.error("Network request failed")
```

`LogLens.logger()` defaults the category to the current file name.

### Type-based logger

```swift
import SwiftLogLens

final class NetworkClient: LogLensLogging {
    func fetch() {
        Self.log.debug("Request started")
    }
}
```

If you prefer an explicit stored logger, use the concrete type name:

```swift
import SwiftLogLens

final class NetworkClient {
    private static let log = LogLens.logger(for: NetworkClient.self)

    func fetch() {
        Self.log.debug("Request started")
    }
}
```

### Explicit category

```swift
import SwiftLogLens

let log = LogLens.logger("network")
let typedLog = LogLens.logger(Logs.network)

log.info("Started")
typedLog.error("Request failed")
```

### Direct `Logger` access

If you want raw `OSLog` features, grab a `Logger` directly from the core product:

```swift
import SwiftLogLens

let logger = LogLens.osLogger(for: NetworkClient.self)
logger.log("Fetched token \(token, privacy: .private)")
```

## Optional macros

Macros are now opt-in.

```swift
import SwiftLogLens
import SwiftLogLensMacros

#loglens("Boot finished")
#loglens(category: "network", .info, "Request started")
```

If `category:` is not passed, the macro resolves category in this order:

1. `@LoglensCategrory(...)` / `@LoglensCategory(...)` on the enclosing type
2. Enclosing type name
3. File name

```swift
import SwiftLogLens
import SwiftLogLensMacros

@LoglensCategory(Logs.networkUtil)
final class NetworkUtil {
    func fetch() {
        #loglens("Request started")
    }
}
```

Macros preserve the convenient call-site behavior, but they also add compile-time overhead. Keep them optional unless you specifically want that tradeoff.

## Config

```swift
LogLensConfig.setSubsystem("com.mycompany.myapp")
LogLensConfig.storeInMemory(true)
LogLensConfig.storeOnDisk(true)
LogLensConfig.setAppGroup("group.com.mycompany.myapp")
```

## Viewing logs in-app

```swift
NavigationStack {
    LogLensView(categoryType: Logs.self)
}
```

## Disk log file access

```swift
let url = LogStore.logURL
await LogLens.store.pruneLogs(olderThanDays: 5)
```
