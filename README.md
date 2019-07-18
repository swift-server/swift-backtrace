# Backtrace

This Swift package provides support for automatically printing crash backtraces of Swift programs.

## Usage

Add `https://github.com/ianpartridge/swift-backtrace.git` as a dependency in your `Package.swift`.

Then, in your `main.swift`, do:

```swift
import Backtrace

// Do this first
Backtrace.install()
```

Finally, make sure you build your application with debug symbols enabled:

```
$ swift build -c release -Xswiftc -g
```

When your app crashes, a stacktrace will be printed to `stderr`.

## Acknowledgements

@weissi, for the signal handling code!
