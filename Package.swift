// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "swift-backtrace",
    products: [
        .library(
            name: "Backtrace",
            targets: ["Backtrace"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(name: "Backtrace",
                dependencies: ["CBacktrace", "CLibUnwind"]),
        .target(name: "CBacktrace",
                dependencies: []),
        .target(name: "CLibUnwind",
                dependencies: []),
        .target(name: "Sample",
                dependencies: ["Backtrace"]),
        .testTarget(name: "BacktraceTests",
                    dependencies: ["Backtrace"]),
    ]
)
