// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "swift-backtrace",
    products: [
        .library(
            name: "Backtrace",
            targets: ["Backtrace"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Backtrace",
                dependencies: ["CBacktrace"]),
        .target(name: "CBacktrace",
                dependencies: []),
        .testTarget(name: "BacktraceTests",
                dependencies: ["Backtrace"])
        ]
)
