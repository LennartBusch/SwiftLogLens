
# SwiftLogLens

  

SwiftUILogLens is a warpper around Swifts unified logging system. SwiftUILogLens allows the fetching and displaying of logs from the log store during runtime on device.

  

The package is named SwiftLogLens for better distinction from other packages. However, the packages uses in most cases the abbreviated version LogLens.

  

## Getting started

To use LogLens you need to create an enum that conforms to the protocol LogCategory.

  

This enum is used to differentiate between loggers for certain areas of you code. Think of Networking, LocationServics, etc.

```swift

import SwifLogLens

  

enum Log: String, LogCategory{

var id: Self {self}

case Network, LocationService

}

```

  

## Logging

Create a logger instance by calling the initalizer

  

```swift

let logLens = LogLens(category: Log.Network)

```

  

The recommended way to log is using the __**osLogger**__ attribute of a LogLens instance. This allows to use all features as privacy redaction, persiting, etc.

  

```swift

let logger = LogLens(category: Log.Network).osLogger

  

logger.log("A message")

logger.error("An error Message")

logger.log("A public message from \(user, privacy: .public)")

```

### WatchOS

However, on watchOS logs are not persited into the logstore by default. This requires the installment of an [profile](https://developer.apple.com/bug-reporting/profiles-and-logs/). This profile is only valid for 3 days, before it needs to be reinstalled.

To migate this problem during testing times, where this might not be feasible, LogLens supports storing logs in memory.

  

```swift

let logger = LogLens(category: Log.Network)

logger.log("A message")

logger.log(level: .error, "An error message")

```

### `#loglens` macro

For clickable call sites in the Xcode log console, use the macro-based API:

```swift
#loglens("Loaded view")
#loglens(.error, "Network failed")
#loglens(category: "networking", .debug, "Request started")
```

The macro expands the `Logger.log(...)` call at the caller location, so Xcode can jump to the source line that emitted the log.

If you do not pass `category`, LogLens resolves it in this order:
1. `@LoglensCategrory(...)` / `@LoglensCategory(...)` on the enclosing type
2. Enclosing type name (`class`/`struct`/`actor`/`enum`)
3. Filename (without `.swift`)

Example with `LogCategory` enum case:

```swift
enum Logs: String, LogCategory {
    var id: Self { self }
    case networkUtil
}

@LoglensCategrory(Logs.networkUtil)
final class NetworkUtil {
    func fetch() {
        #loglens("Request started") // category: "networkUtil"
    }
}
```

  

## Configuration

LogLens allows customization of the default settings

```swift

// Changes the identifier of the subsystem LogLens writes to. Defaults to the Bundle identifier

LogLensConfig.setSubsystem("My Subsystem")

  

//Necessary on watchOS, when writing to memory. Defaults to false

LogLensConfig.setStoreOnWrite(true)

```

  

  

## Viewing Logs

LogLens contains a view, where logs can be fetched and displayed. This view must be inside a NavigationStack, otherwise the fetch button wont be visible.

  

Furthermore the view contains a picker, to filter the displayed logs. For this the LogCategory must be given.

```swift

LogLensView(categoryType: Log.self)

```

## Persisten Storing on Disk

With the execption of macOS, logs can't be accessed during runtime from the store. LogLens includes the option to write logs to disk in human readable format. With this logs could be for example loaded by users. 

To enable persistent writing set the corresponding flag
```swift
LogLensConfig.setWriteToDisk(true)
```

Logs can be retrieved from the device using the url of the written logs
```swift
LogStore.logURL
```
Logs can be pruned, to keep only new logs
```swift
LogStore.pruneLogs(olderThanDays: 5) //Deletes all logs older than 5 days
```
