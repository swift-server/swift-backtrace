# ``Backtrace``

Provides support for automatically printing crash backtraces of Swift programs.

## Overview

The Backtrace library is designed to fill a gap in backtraces support for Swift on non-Darwin platforms.
When this gap is closed at the language runtime level, this library will become redundant and be deprecated.

## Getting started

When building web-services and daemons, direct usage of this library is discouraged.
Instead, use [swift-service-lifecycle](https://github.com/swift-server/swift-service-lifecycle) which helps manage the application lifecycle including setting up backtraces hooks when needed.

Add `https://github.com/swift-server/swift-backtrace.git` as a dependency in your `Package.swift`.

### Crash backtraces

In your `main.swift`, do:

```swift
import Backtrace

// Do this first
Backtrace.install()
```

Finally, for Swift < 5.2, make sure you build your application with debug symbols enabled. Debug symbols are automatically included for Swift 5.2 and above.

```
$ swift build -c release -Xswiftc -g
```

When your app crashes, a stacktrace will be printed to `stderr`.
