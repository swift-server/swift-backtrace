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

let reason = CommandLine.arguments.count == 2 ? CommandLine.arguments[1] : "unknown"
Backtrace.install()
fatalError(reason)
