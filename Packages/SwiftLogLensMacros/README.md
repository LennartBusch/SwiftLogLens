# SwiftLogLensMacros

Macro companion package for `SwiftLogLens`.

This package is intentionally separate so apps that only use `SwiftLogLens` do not pull a macro target into Xcode's editor trust flow.

## Local development

This package depends on the core package via a local path:

```swift
.package(path: "../..")
```

If you publish this package separately, replace that with the URL for the core `SwiftLogLens` package.
