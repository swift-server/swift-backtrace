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
    func testFatalError() throws {
        #if !os(Linux)
        try XCTSkipIf(true, "test is only supported on Linux")
        #endif

        #if swift(>=5.9)
        try XCTSkipIf(true, "test is not supported on Swift 5.9")
        #endif

        let expectedError = UUID().uuidString
        let stderr = try runSample(reason: expectedError)
        print(stderr)

        XCTAssert(stderr.contains("Received signal 4. Backtrace:"))
        XCTAssert(stderr.contains("Current stack trace:"), "expected stanard error to include backtrace")
        XCTAssert(stderr.contains("Fatal error: \(expectedError)"), "expected stanard error to include error information")
    }

    func testSIGILL() throws {
        #if !os(Linux)
        try XCTSkipIf(true, "test is only supported on Linux")
        #endif

        #if swift(>=5.9)
        try XCTSkipIf(true, "test is not supported on Swift 5.9")
        #endif

        let stderr = try runSample(reason: "SIGILL")
        print(stderr)

        XCTAssert(stderr.contains("Received signal \(SIGILL). Backtrace:"))
        XCTAssert(stderr.contains("Sample.raiseSignal"))
    }

    func testSIGSEGV() throws {
        #if !os(Linux)
        try XCTSkipIf(true, "test is only supported on Linux")
        #endif

        #if swift(>=5.9)
        try XCTSkipIf(true, "test is not supported on Swift 5.9")
        #endif

        let stderr = try runSample(reason: "SIGSEGV")
        print(stderr)

        XCTAssert(stderr.contains("Received signal \(SIGSEGV). Backtrace:"))
        XCTAssert(stderr.contains("Sample.raiseSignal"))
    }

    func testSIGBUS() throws {
        #if !os(Linux)
        try XCTSkipIf(true, "test is only supported on Linux")
        #endif

        #if swift(>=5.9)
        try XCTSkipIf(true, "test is not supported on Swift 5.9")
        #endif

        let stderr = try runSample(reason: "SIGBUS")
        print(stderr)

        XCTAssert(stderr.contains("Received signal \(SIGBUS). Backtrace:"))
        XCTAssert(stderr.contains("Sample.raiseSignal"))
    }

    func testSIGFPE() throws {
        #if !os(Linux)
        try XCTSkipIf(true, "test is only supported on Linux")
        #endif

        #if swift(>=5.9)
        try XCTSkipIf(true, "test is not supported on Swift 5.9")
        #endif

        let stderr = try runSample(reason: "SIGFPE")
        print(stderr)

        XCTAssert(stderr.contains("Received signal \(SIGFPE). Backtrace:"))
        XCTAssert(stderr.contains("Sample.raiseSignal"))
    }

    func runSample(reason: String) throws -> String {
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["run", "Sample", reason]
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}
