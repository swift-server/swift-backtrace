import Foundation

// Overshadows the `swift_willThrow` function in the standard library. The compiler emits a call to
// `swift_willThrow` when generating a `throw` statement.
//
// Only binaries that link against `ErrorBacktrace` are expected to use this implementation of
// `swift_willThrow` instead of the standard library's. Runtime dynamic linker shenanigans are inherently
// unsafe and hard to predict -- it's possible that this implementation will never be called, or will be
// called at unexpected times.
//
// While knowledge of `swift_willThrow` is shared between Swift and Xcode, its existence and behavior is
// undocumented and subject to change at any time.
@_silgen_name("swift_willThrow")
@inline(never)
public func swiftWillThrowImpl() {
    Backtrace.swiftWillThrow(skip: 9)
}

class ThreadLocal<T>: NSObject, NSCopying {
    private let mCreate: () -> T

    public init(create: @escaping () -> T) {
        mCreate = create
    }

    public func get() -> T {
        get(on: .current)
    }

    public func get(on thread: Thread) -> T {
        let threadDictionary = thread.threadDictionary
        if let cachedObject = threadDictionary[self] as? T {
            return cachedObject
        } else {
            let newObject = mCreate()
            threadDictionary.setObject(newObject, forKey: self)
            return newObject
        }
    }

    public func set(_ newObject: T) {
        let threadDictionary = Thread.current.threadDictionary
        threadDictionary.setObject(newObject, forKey: self)
    }

    public func remove() {
        let threadDictionary = Thread.current.threadDictionary
        threadDictionary.removeObject(forKey: self)
    }

    func copy(with zone: NSZone? = nil) -> Any {
        /*"SWIFT_ERROR_BACKTRACE_THROWN_CALLSTACK"*/
        self
    }
}