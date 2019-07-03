// swift-tools-version:5.0

import PackageDescription

var backtraceDependencies: [Target.Dependency] = []

#if os(Linux)
backtraceDependencies.append(.target(name: "CBacktrace"))
#endif

var targets: [Target] = [
    .target(
        name: "Backtrace",
        dependencies: backtraceDependencies),
    .testTarget(
        name: "BacktraceTests",
        dependencies: ["Backtrace"])
]

#if os(Linux)
targets.append(
    .target(
        name: "CBacktrace",
        dependencies: [])
)
#endif


let package = Package(
    name: "swift-backtrace",
    products: [
        .library(
            name: "Backtrace",
            targets: ["Backtrace"]),
    ],
    dependencies: [],
    targets: targets
)
