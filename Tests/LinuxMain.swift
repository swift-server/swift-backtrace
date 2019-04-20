import XCTest

import BacktraceTests

var tests = [XCTestCaseEntry]()
tests += BacktraceTests.allTests()
XCTMain(tests)
