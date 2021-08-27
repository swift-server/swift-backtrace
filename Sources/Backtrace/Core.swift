import libbacktrace
import Signals

#if os(Linux) || os(Android)
import Glibc
#elseif os(macOS)
import Darwin
#endif

#if os(Android)
import AndroidSwiftLogcat
#endif

typealias CBacktraceErrorCallback = @convention(c) (_ data: UnsafeMutableRawPointer?, _ msg: UnsafePointer<CChar>?, _ errnum: CInt) -> Void
typealias CBacktraceFullCallback = @convention(c) (_ data: UnsafeMutableRawPointer?, _ pc: UInt, _ filename: UnsafePointer<CChar>?, _ lineno: CInt, _ function: UnsafePointer<CChar>?) -> CInt
typealias CBacktraceSimpleCallback = @convention(c) (_ data: UnsafeMutableRawPointer?, _ pc: UInt) -> CInt
typealias CBacktraceSyminfoCallback = @convention(c) (_ data: UnsafeMutableRawPointer?, _ pc: UInt, _ filename: UnsafePointer<CChar>?, _ symval: UInt, _ symsize: UInt) -> Void

private let state = backtrace_create_state(CommandLine.arguments[0], /* BACKTRACE_SUPPORTS_THREADS */ 1, nil, nil)

/// This should return 0 to continuing tracing.
typealias BacktraceFullCallback<T> = (
        _ data: inout T,
        _ pc: UInt64,
        _ filename: String,
        _ lineno: Int,
        _ function: String
) -> Int

typealias BacktraceErrorCallback<T> = (
        _ data: inout T,
        _ msg: String,
        _ errnum: Int
) -> Void

typealias BacktraceContext<T> = (T, BacktraceFullCallback<T>, BacktraceErrorCallback<T>)

private let cFullCallback: CBacktraceFullCallback = {
    (contextPtr: UnsafeMutableRawPointer?,
     pc: UInt,
     filename: UnsafePointer<CChar>?,
     lineno: CInt,
     function: UnsafePointer<CChar>?) -> CInt in

    var continuingTracing: CInt = -1;
    if let ctxPtr = contextPtr {
        let ctxPtr: UnsafeMutablePointer<BacktraceContext<Backtrace>> =
                ctxPtr.assumingMemoryBound(to: BacktraceContext<Backtrace>.self)
        var data: Backtrace = ctxPtr.pointee.0
        var symbol: String = "";
        if let fn = function {
            let fn = String(cString: fn)
            if fn.hasPrefix("$s") || fn.hasPrefix("$S") {
                symbol = _stdlib_demangleName(fn)
            }
        }
        var file: String = "";
        if let filename = filename {
            file = String(cString: filename)
        }
        // print(data, pc, symbol, file, lineno)

        let fcb: BacktraceFullCallback<Backtrace> = ctxPtr.pointee.1
        continuingTracing = CInt(fcb(&data, UInt64(pc), file, Int(lineno), symbol))
        ctxPtr.pointee.0 = data;
    }

    return continuingTracing
}

private let cErrorCallback: CBacktraceErrorCallback = {
    (contextPtr: UnsafeMutableRawPointer?, msg: UnsafePointer<CChar>?, errNum: CInt) in

    if let ctxPtr = contextPtr {
        let ctxPtr: UnsafeMutablePointer<BacktraceContext<Backtrace>> =
                ctxPtr.assumingMemoryBound(to: BacktraceContext<Backtrace>.self)
        var data: Backtrace = ctxPtr.pointee.0
        var message: String = "";
        if let msg = msg {
            message = String(cString: msg)
        }
        // print(data, message, errNum)

        let ecb: BacktraceErrorCallback<Backtrace> = ctxPtr.pointee.2
        ecb(&data, message, Int(errNum))
        ctxPtr.pointee.0 = data;
    }
}

func backtraceFull(skip: Int,
                   fullCallback: @escaping BacktraceFullCallback<Backtrace>,
                   errorCallback: @escaping BacktraceErrorCallback<Backtrace>) -> Backtrace {
    var context: BacktraceContext<Backtrace> = (Backtrace(frames: []), fullCallback, errorCallback)
    _ = withUnsafeMutablePointer(to: &context) { contextPtr in
        backtrace_full(
                state,
                Int32(skip),
                cFullCallback,
                cErrorCallback,
                contextPtr)
    }
    return context.0;
}

@inline(__always)
func currentImpl(skip: Int) -> Backtrace {
    backtraceFull(
            skip: skip,
            fullCallback: { (
                    data: inout Backtrace,
                    pc: UInt64,
                    filename: String,
                    lineno: Int,
                    function: String) in

                data.frames.append(StackFrame(
                        pc: pc,
                        symbol: function,
                        file: filename,
                        lineNum: lineno))

                data.frames = data.frames.filter { (sf: StackFrame) in
                    !sf.symbol.isEmpty || !sf.file.isEmpty
                }

                return 0
            },
            errorCallback: { (
                    data: inout Backtrace,
                    msg: String,
                    errNum: Int) in

                data.error = StackError(errorNum: errNum, message: msg)
            }
    )
}

@inline(__always)
func setupHandlerImpl() {
    let flags = CInt(SA_NODEFER) | CInt(bitPattern: CUnsignedInt(SA_RESETHAND))
    let mask = sigset_t()

    Signals.trap(signals: [.ill, .trap], mask: mask, flags: flags) { (signal: CInt) in
        if (signal == Signals.Signal.ill.valueOf || signal == Signals.Signal.trap.valueOf) {

            let bt: Backtrace = (currentImpl(skip: 11))

            if let stackError = bt.error {
                #if os(macOS)
                print(stackError)
                #elseif os(Linux)
                _ = withUnsafePointer(to: &stackError.description) {
                    descriptionPtr
                    withVaList([descriptionPtr]) { vaList in
                        vfprintf(stderr, "%s\n", vaList)
                    }
                }
                #elseif os(Android)
                AndroidLogcat.e("SwiftNativeBackTraceError", "\(stackError)\n")
                #endif
            } else {
                #if os(macOS)
                print(
                        """

                        \(bt)
                        \n
                        """
                )
                exit(EXIT_FAILURE)
                #elseif os(Linux)
                bt.description.withCString { ptr in
                    _ = withVaList([ptr]) { vaList in
                        vfprintf(stderr, "%s", vaList)
                    }
                }
                #elseif os(Android)
                bt.frames.forEach {
                    AndroidLogcat.e("SwiftNativeBackTraceFull", $0.description)
                }
                #endif
            }
        }
    }
}