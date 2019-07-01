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

The stacktrace will likely not be fully symbolicated, because the `backtrace_symbols()` API this package uses only supports ELF symbols and does not read DWARF debugging symbols. To get full symbolication and demangling of Swift function names, run this one-liner over the stacktrace:

```shell
cat stacktrace.txt | tr '()' '  ' | while read bin addr junk; do addr2line -e "$bin" -a "$addr" -ipf; done | swift demangle
```

## Acknowledgements

@weissi, for the code!
