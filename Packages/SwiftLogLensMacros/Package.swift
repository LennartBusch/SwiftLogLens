// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SwiftLogLensMacros",
    platforms: [.iOS(.v16), .watchOS(.v9), .macOS(.v13)],
    products: [
        .library(
            name: "SwiftLogLensMacros",
            targets: ["SwiftLogLensMacros"]
        ),
    ],
    dependencies: [
        .package(name: "SwiftLogLens", path: "../.."),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .target(
            name: "SwiftLogLensMacros",
            dependencies: [
                .product(name: "SwiftLogLens", package: "SwiftLogLens"),
                "SwiftLogLensCompilerPlugin",
            ]
        ),
        .macro(
            name: "SwiftLogLensCompilerPlugin",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]
        ),
    ]
)
