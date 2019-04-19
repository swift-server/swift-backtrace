import XCTest

import BacktraceTests

var tests = [XCTestCaseEntry]()
tests += backtraceTests.allTests()
XCTMain(tests)
