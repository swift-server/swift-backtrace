// swift-tools-version:5.3

import PackageDescription

let package = Package(
        name: "swift-backtrace",
        products: [
            .library(
                    name: "Backtrace",
                    type: .dynamic,
                    targets: ["Backtrace"]),
            .executable(name: "Example", targets: ["Example"]),
        ],
        dependencies: [
            .package(name: "Signals", url: "https://github.com/Guang1234567/Swift_Signals.git", .branch("android_support")),
            .package(name: "AndroidSwiftLogcat", url: "https://github.com/Guang1234567/swift-android-logcat.git", .branch("master")),
        ],
        targets: [
            /*.target(name: "Backtrace",
                    dependencies: ["CBacktrace", "AndroidSwiftLogcat",]),
            .target(name: "CBacktrace",
                    dependencies: []),*/
            .target(
                    name: "Backtrace",
                    dependencies: [
                        "libbacktrace",
                        "Signals",
                        .byName(name: "AndroidSwiftLogcat", condition: .when(platforms: [.android]))
                    ],
                    cSettings: [
                        .unsafeFlags([
                            "-funwind-tables",
                        ]),
                    ],
                    swiftSettings: [
                        .unsafeFlags([
                            "-g",
                        ]),
                    ]
            ),
            .target(name: "libbacktrace",
                    dependencies: [],
                    exclude: [
                        "edtest.c",
                        "edtest2.c",
                        "ztest.c",
                        "xztest.c",
                        "xcoff.c",
                        "unknown.c",
                        "unittest.c",
                        "ttest.c",
                        "test_format.c",
                        "stest.c",
                        "read.c",
                        "nounwind.c",
                        "mtest.c",
                        "instrumented_alloc.c",
                        "btest.c",
                        "allocfail.c",
                        "alloc.c",
                        //
                        "config",
                        "config.h.in",
                        "libtool.m4",
                        "ltsugar.m4",
                        "compile",
                        "install-debuginfo-for-buildid.sh.in",
                        "missing",
                        "Isaac.Newton-Opticks.txt",
                        "aclocal.m4",
                        "Makefile.am",
                        "allocfail.sh",
                        "LICENSE",
                        "move-if-change",
                        "install-sh",
                        "configure",
                        "Makefile.in",
                        "test-driver",
                        "ltversion.m4",
                        "config.log",
                        "README.md",
                        "config.guess",
                        "backtrace-supported.h.in",
                        "ltoptions.m4",
                        "lt~obsolete.m4",
                        "configure.ac",
                        "ltmain.sh",
                        "config.sub",
                        "filetype.awk",
                    ],
                    publicHeadersPath: "."/*,
                    cSettings: [
                        .define("HAVE_MACH_O_DYLD_H", to: "1", .when(platforms: [.macOS, .watchOS, .iOS, ])),
                        .define("HAVE_MACH_O_DYLD_H", to: "0", .when(platforms: [.linux, .android])),
                    ]*/
            ),
            .target(
                    name: "Example",
                    dependencies: ["Backtrace", ],
                    cSettings: [
                        .unsafeFlags([
                            "-funwind-tables",
                        ]),
                    ],
                    swiftSettings: [
                        .unsafeFlags([
                            "-g",
                        ]),
                    ]
            ),
            .testTarget(name: "BacktraceTests",
                    dependencies: ["Backtrace"])
        ]
)
