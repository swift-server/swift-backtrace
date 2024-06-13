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

/// Formatter for one backtrace line.
///
/// - Parameter pc: String formated value for PC register ("0x123456789AB").
/// - Parameter function: full unmangled function name if available.
/// - Parameter fileName: tuple containing `(full path, line)` if available.
/// - Returns: The formatted line to print, or `nil` if it should be skipped.
public typealias Formatter = (_ pc: String, _ function: String?, _ file: (String, Int)?) -> String?

/// Different built-in formats for backtraces.
public enum Format {
    /// Displays all information on one line.
    /// Contains all backtrace lines, including those from Backtrace itself.
    /// Useful for debugging full dumps.
    case full

    /// Formats the information on multiple lines with colors, without PC register.
    /// Top backtrace lines from Backtrace itself are ignored.
    /// More readable than ``Format/full`` when shown in a short terminal but
    /// takes up more vertical space.
    case colored

    /// Runs the given formatter to format each line individually.
    /// - Parameter formatter: The formatter to run.
    /// - Parameter skip: How many backtrace lines to skip at the top.
    case custom(formatter: Formatter, skip: Int)

    /// Default format.
    public static let `default` = Format.full

    internal var skip: Int {
        switch self {
            case .full: return 0
            case .colored: return 4 // low enough to be safe on Linux and Windows but still reduce output noise
            case .custom(_, let skip): return skip
        }
    }

    internal var formatter: Formatter {
        switch self {
            case .full: return fullFormatter
            case .colored: return coloredFormatter
            case .custom(let formatter, _): return formatter
        }
    }
}

let fullFormatter: Formatter = { (_ pc: String, _ function: String?, _ file: (String, Int)?) -> String? in
    var str = pc

    if let function = function {
        str.append(", ")
        str.append(function)
    }

    if let (fileName, line) = file {
        str.append(" at ")
        str.append(fileName)
        str.append(":")
        str.append(String(line))
    }

    str.append("\n")

    return str
}

let coloredFormatter: Formatter = { (_ pc: String, _ function: String?, _ file: (String, Int)?) -> String? in
    let red = "\u{001B}[91m"
    let reset = "\u{001B}[0m"

    var str = ""

    if let function = function {
        str.append("    at ")
        str.append(red)
        str.append(function)
        str.append(reset)
    } else {
        str.append("    at <unavailable>")
    }

    str.append("\n")

    if let (fileName, line) = file {
        str.append("       ")
        str.append(fileName)
        str.append(":")
        str.append(String(line))
        str.append("\n")
    }

    return str
}
