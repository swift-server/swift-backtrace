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

Finally, make sure you build your application with debug symbols enabled:

```
$ swift build -c release -Xswiftc -g
```

When your app crashes, a stacktrace will be printed to `stderr`.


## Acknowledgements

Ian Partridge ([GitHub](https://github.com/ianpartridge/), [Twitter](https://twitter.com/alfa)) the original author of this package.

Johannes Weiss ([GitHub](https://github.com/weissi), [Twitter](https://twitter.com/johannesweiss)) for the signal handling code.
