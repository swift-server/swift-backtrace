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
        .target(
            name: "CBacktrace",
            dependencies: []),
        .target(
            name: "Backtrace",
            dependencies: [.target(name: "CBacktrace")]),
        .testTarget(
            name: "BacktraceTests",
            dependencies: ["Backtrace"])
    ]
)
