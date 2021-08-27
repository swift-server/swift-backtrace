import Foundation
import libbacktrace

#if os(Linux) || os(Android)
import Glibc
#elseif os(macOS)
import Darwin
#endif

#if os(Android)
import AndroidSwiftLogcat
#endif


public struct Backtrace: CustomStringConvertible, CustomDebugStringConvertible {

    private static let kThrownCallStack: ThreadLocal<Backtrace> = ThreadLocal() {
        Backtrace(frames: [])
    }

    public internal(set) var frames: [StackFrame]

    public internal (set) var error: StackError?

    public init(frames: [StackFrame], error: StackError? = nil) {
        self.frames = frames
        self.error = error
    }

    public var debugDescription: String {
        frames.map {
            $0.description
        }.joined(separator: "\n")
    }

    public var description: String {
        debugDescription
    }

    public static func install() {
        setupHandlerImpl()
    }

    /// The backtrace for the current stack frame.
    public static var current: Backtrace {
        currentImpl(skip: 8)
    }


    /// The backtrace at the last time an error was thrown on this thread.
    public static var lastThrown: Backtrace {
        lastThrownBacktrace(on: .current)
    }

    /// The backtrace at the last time an error was thrown on the given `thread`.
    public static func lastThrownBacktrace(on thread: Thread) -> Backtrace {
        return kThrownCallStack.get(on: thread)
    }

    @inline(__always)
    public static func swiftWillThrow(skip: Int) {
        var backtrace: Backtrace = currentImpl(skip: skip)
        /*backtrace.frames = backtrace.frames.filter {
            !$0.file.contains("/<compiler-generated>")
        }*/
        backtrace.frames = backtrace.frames.enumerated()
                .filter { (idx: Int, sf: StackFrame) in
                    (idx < 1 || idx > 5) // ignore closure created by `Backtrace.capture(from: ...)`
                            && (!sf.symbol.isEmpty || !sf.file.isEmpty)
                }.map { (_: Int, sf: StackFrame) -> StackFrame in
                    /*#if os(Android)
                    AndroidLogcat.d("SwiftBackTrace", "\(sf)")
                    #endif*/
                    return sf
                }

        kThrownCallStack.set(backtrace)

        /*#if os(Android)
        AndroidLogcat.e("SwiftBackTrace", "swift_willThrow")
        #endif*/
    }

    /// Calls `body` and wraps any error it throws in a type that describes the backtrace when it was thrown.
    public static func capture<T>(from body: () throws -> T) throws -> T {
        do {
            return try body()
        } catch {
            throw Captured.error(error, lastThrown)
        }
    }

    public enum Captured: Error, CustomStringConvertible, CustomDebugStringConvertible {
        case error(Error, Backtrace)

        public var description: String {
            debugDescription
        }

        public var debugDescription: String {
            switch self {
            case let .error(error, backtrace):
                return """
                       \(error)

                       Backtrace:

                       \(backtrace)
                       """

            }
        }
    }
}

public struct StackFrame: CustomStringConvertible, CustomDebugStringConvertible {
    public let pc: UInt64
    public let symbol: String
    public let file: String
    public let lineNum: Int

    public var description: String {
        debugDescription
    }
    public var debugDescription: String {
        String(
                format: "%@, %@\n    at %@:%u",

                "\(String(format: "%p", pc)) (\(pc))".withCString(encodedAs: UTF16.self) {
                    String(format: "%S", $0)
                },

                symbol,

                file.withCString(encodedAs: UTF16.self) {
                    String(format: "%S", $0)
                },

                lineNum
        )
    }
}

public struct StackError: CustomStringConvertible, CustomDebugStringConvertible {
    public let errorNum: Int
    public let message: String

    public init(errorNum: Int, message: String) {
        self.errorNum = errorNum
        self.message = message
    }

    public var description: String {
        debugDescription
    }
    public var debugDescription: String {
        "StackError(errorNum: \(errorNum), message: \(message))"
    }
}
