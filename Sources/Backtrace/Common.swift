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

#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#else
#error("Unsupported platform.")
#endif

extension Backtrace {
    static func printFrame(_ pc: UInt, filename: String?, lineno: UInt, function: String?) {
        var str = "0x"
        str.append(String(pc, radix: 16))
        if let function = function {
            str.append(", ")
            str.append(_stdlib_demangleName(function))
        }
        if let filename = filename {
            str.append(" at ")
            str.append(filename)
            str.append(":")
            str.append(String(lineno))
        }
        str.append("\n")

        str.withCString { ptr in
            _ = withVaList([ptr]) { vaList in
                vfprintf(stderr, "%s", vaList)
            }
        }
    }
}
