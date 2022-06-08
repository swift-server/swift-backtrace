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

import Backtrace
#if canImport(Darwin)
import Darwin
#elseif os(Linux)
import Glibc
#endif

Backtrace.install()

func raiseSignal(_ signal: Int32) {
    raise(signal)
}

let reason = CommandLine.arguments.count == 2 ? CommandLine.arguments[1] : "unknown"
switch reason.uppercased() {
case "SIGILL":
    raiseSignal(SIGILL)
case "SIGSEGV":
    raiseSignal(SIGSEGV)
case "SIGBUS":
    raiseSignal(SIGBUS)
case "SIGFPE":
    raiseSignal(SIGFPE)
default:
    fatalError(reason)
}
