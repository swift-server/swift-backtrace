//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftLinuxBacktrace open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftLinuxBacktrace project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftLinuxBacktrace project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTest

public final class BacktraceTests: XCTestCase {
    func testBacktrace() {
        let expectedError = UUID().uuidString
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["run", "Sample", expectedError]
        process.standardError = pipe
        XCTAssertNoThrow(try process.run())
        if process.isRunning {
            process.waitUntilExit()
        }
        let stderr = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        print(stderr)
        XCTAssert(stderr.contains("Current stack trace:"), "expected stanard error to include backtrace")
        XCTAssert(stderr.contains("Fatal error: \(expectedError)"), "expected stanard error to include error information")
    }
}
