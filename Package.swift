// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SwiftLogLens",
    platforms: [.iOS(.v16), .watchOS(.v9) , .macOS(.v13)],
    products: [
        .library(
            name: "SwiftLogLens",
            targets: ["SwiftLogLens"]),
        .library(
            name: "SwiftLogLensMacros",
            targets: ["SwiftLogLensMacros"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .target(
            name: "SwiftLogLens"
        ),
        .target(
            name: "SwiftLogLensMacros",
            dependencies: [
                "SwiftLogLens",
                "SwiftLogLensCompilerPlugin",
            ],
            path: "Sources/SwiftLogLensMacrosAPI"
        ),
        .macro(
            name: "SwiftLogLensCompilerPlugin",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ],
            path: "Sources/SwiftLogLensMacros"
        ),
    ]
)
