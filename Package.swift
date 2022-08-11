// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "swift-backtrace",
    products: [
        .library(
            name: "Backtrace",
            targets: ["Backtrace"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(name: "Backtrace",
                dependencies: ["CBacktrace"]),
        .target(name: "CBacktrace",
                dependencies: []),
        .executableTarget(name: "Sample",
                          dependencies: ["Backtrace"]),
        .testTarget(name: "BacktraceTests",
                    dependencies: ["Backtrace"]),
    ]
)
