// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "swift-backtrace",
    products: [
        .library(
            name: "Backtrace",
            targets: ["Backtrace"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "CBacktrace",
            dependencies: []),
        .target(
            name: "Backtrace",
            dependencies: ["CBacktrace"]),
        .testTarget(
            name: "BacktraceTests",
            dependencies: ["Backtrace"])
    ]
)
