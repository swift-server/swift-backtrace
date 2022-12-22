//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftLinuxBacktrace open source project
//
// Copyright (c) 2019-2022 Apple Inc. and the SwiftLinuxBacktrace project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftLinuxBacktrace project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTest

@testable import Backtrace

public final class FormatsTests: XCTestCase {
    func testFullFormat() {
        let line = fullFormatter(
            "0x123456789AB",
            "FormatsTests.testFullFormat()",
            (file: "Tests/BacktraceTests/FormatsTests.swift", line: 24)
        )

        XCTAssertEqual(line, "0x123456789AB, FormatsTests.testFullFormat() at Tests/BacktraceTests/FormatsTests.swift:24\n")
    }

    func testFullFormatNoFunction() {
        let line = fullFormatter(
            "0x123456789AB",
            nil,
            (file: "Tests/BacktraceTests/FormatsTests.swift", line: 24)
        )

        XCTAssertEqual(line, "0x123456789AB at Tests/BacktraceTests/FormatsTests.swift:24\n")
    }

    func testFullFormatNoFile() {
        let line = fullFormatter(
            "0x123456789AB",
            "FormatsTests.testFullFormat()",
            nil
        )

        XCTAssertEqual(line, "0x123456789AB, FormatsTests.testFullFormat()\n")
    }

    func testFullFormatNoFileNoFunction() {
        let line = fullFormatter(
            "0x123456789AB",
            nil,
            nil
        )

        XCTAssertEqual(line, "0x123456789AB\n")
    }

    func testColoredFormat() {
        let line = coloredFormatter(
            "0x123456789AB",
            "FormatsTests.testFullFormat()",
            (file: "Tests/BacktraceTests/FormatsTests.swift", line: 24)
        )

        XCTAssertEqual(line, "    at \u{001B}[91mFormatsTests.testFullFormat()\u{001B}[0m\n       Tests/BacktraceTests/FormatsTests.swift:24\n")
    }

    func testColoredFormatNoFunction() {
        let line = coloredFormatter(
            "0x123456789AB",
            nil,
            (file: "Tests/BacktraceTests/FormatsTests.swift", line: 24)
        )

        XCTAssertEqual(line, "    at <unavailable>\n       Tests/BacktraceTests/FormatsTests.swift:24\n")
    }

    func testColoredFormatNoFile() {
        let line = coloredFormatter(
            "0x123456789AB",
            "FormatsTests.testFullFormat()",
            nil
        )

        XCTAssertEqual(line, "    at \u{001B}[91mFormatsTests.testFullFormat()\u{001B}[0m\n")
    }

    func testColoredFormatNoFileNoFunction() {
        let line = coloredFormatter(
            "0x123456789AB",
            nil,
            nil
        )

        XCTAssertEqual(line, "    at <unavailable>\n")
    }
}
