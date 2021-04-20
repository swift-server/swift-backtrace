# Backtrace

This Swift package provides support for automatically printing crash backtraces of Swift programs.

## Usage

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


## Acknowledgements

Ian Partridge ([GitHub](https://github.com/ianpartridge/), [Twitter](https://twitter.com/alfa)) the original author of this package.

Johannes Weiss ([GitHub](https://github.com/weissi), [Twitter](https://twitter.com/johannesweiss)) for the signal handling code.

Saleem Abdulrasool ([GitHub](https://github.com/compnerd), [Twitter](https://twitter.com/compnerd)) for the Windows port.
