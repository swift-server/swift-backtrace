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

#if os(Linux)
import CBacktrace
import Glibc

typealias CBacktraceErrorCallback = @convention(c) (_ data: UnsafeMutableRawPointer?, _ msg: UnsafePointer<CChar>?, _ errnum: CInt) -> Void
typealias CBacktraceFullCallback = @convention(c) (_ data: UnsafeMutableRawPointer?, _ pc: UInt, _ filename: UnsafePointer<CChar>?, _ lineno: CInt, _ function: UnsafePointer<CChar>?) -> CInt
typealias CBacktraceSimpleCallback = @convention(c) (_ data: UnsafeMutableRawPointer?, _ pc: UInt) -> CInt
typealias CBacktraceSyminfoCallback = @convention(c) (_ data: UnsafeMutableRawPointer?, _ pc: UInt, _ filename: UnsafePointer<CChar>?, _ symval: UInt, _ symsize: UInt) -> Void

private let state = backtrace_create_state(nil, /* BACKTRACE_SUPPORTS_THREADS */ 1, nil, nil)

private var installedFormat: Format = .default

private let callback: CBacktraceFullCallback? = { _, pc, filename, lineno, function in
    let formattedPc = "0x\(String(pc, radix: 16))"

    let demangledFunction: String?
    if let function = function {
        var fn = String(cString: function)
        if fn.hasPrefix("$s") || fn.hasPrefix("$S") {
            fn = _stdlib_demangleName(fn)
        }
        demangledFunction = fn
    } else {
        demangledFunction = nil
    }

    let file: (fileName: String, line: Int)?
    if let filename = filename {
        file = (fileName: String(cString: filename), line: Int(lineno))
    } else {
        file = nil
    }

    if let line = installedFormat.formatter(formattedPc, demangledFunction, file) {
        line.withCString { ptr in
            _ = withVaList([ptr]) { vaList in
                vfprintf(stderr, "%s", vaList)
            }
        }
    }

    return 0
}

private let errorCallback: CBacktraceErrorCallback? = {
    _, msg, errNo in
    if let msg = msg {
        _ = withVaList([msg, errNo]) { vaList in
            vfprintf(stderr, "SwiftBacktrace ERROR: %s (errno: %d)\n", vaList)
        }
    }
}

private func printBacktrace(signal: CInt) {
    _ = fputs("Received signal \(signal). Backtrace:\n", stderr)
    backtrace_full(state, Int32(installedFormat.skip), callback, errorCallback, nil)
    fflush(stderr)
}

public enum Backtrace {
    /// Install the backtrace handler on default signals: `SIGILL`, `SIGSEGV`, `SIGBUS`, `SIGFPE`.
    public static func install(format: Format = .default) {
        Backtrace.install(signals: [SIGILL, SIGSEGV, SIGBUS, SIGFPE], format: format)
    }

    /// Install the backtrace handler when any of `signals` happen.
    public static func install(signals: [CInt], format: Format = .default) {
        installedFormat = format

        for signal in signals {
            self.setupHandler(signal: signal) { signal in
                printBacktrace(signal: signal)
                raise(signal)
            }
        }
    }

    @available(*, deprecated, message: "This method will be removed in the next major version.")
    public static func print() {
        backtrace_full(state, Int32(installedFormat.skip), callback, errorCallback, nil)
    }

    private static func setupHandler(signal: Int32, handler: @escaping @convention(c) (CInt) -> Void) {
        typealias sigaction_t = sigaction
        let sa_flags = CInt(SA_NODEFER) | CInt(bitPattern: CUnsignedInt(SA_RESETHAND))
        var sa = sigaction_t(__sigaction_handler: unsafeBitCast(handler, to: sigaction.__Unnamed_union___sigaction_handler.self),
                             sa_mask: sigset_t(),
                             sa_flags: sa_flags,
                             sa_restorer: nil)
        withUnsafePointer(to: &sa) { ptr -> Void in
            sigaction(signal, ptr, nil)
        }
    }
}

#elseif os(Windows)
#if swift(<5.4)
#error("unsupported Swift version")
#else
import Foundation

@_implementationOnly import CRT
@_implementationOnly import WinSDK
#endif

private var installedFormat: Format = .default

public enum Backtrace {
    private static var MachineType: DWORD {
        #if arch(arm)
        DWORD(IMAGE_FILE_MACHINE_ARMNT)
        #elseif arch(arm64)
        DWORD(IMAGE_FILE_MACHINE_ARM64)
        #elseif arch(i386)
        DWORD(IMAGE_FILE_MACHINE_I386)
        #elseif arch(x86_64)
        DWORD(IMAGE_FILE_MACHINE_AMD64)
        #else
        #error("unsupported architecture")
        #endif
    }

    /// Signal selection unavailable on Windows. Use ``install()-484jy``.
    @available(*, deprecated, message: "signal selection unavailable on Windows")
    public static func install(signals: [CInt], format: Format = .default) {
        Backtrace.install(format: format)
    }

    /// Install the backtrace handler on default signals.
    public static func install(format: Format = .default) {
        installedFormat = format

        // Install a last-chance vectored exception handler to capture the error
        // before the termination and report the stack trace.  It is unlikely
        // that this will be recovered at this point by a SEH handler.
        _ = AddVectoredExceptionHandler(0) { _ in
            // NOTE: GetCurrentProcess does not increment the reference count on
            // the process.  This handle should _not_ be closed upon completion.
            let hProcess: HANDLE = GetCurrentProcess()

            var cxr: CONTEXT = CONTEXT()
            cxr.ContextFlags =
                DWORD(CONTEXT_CONTROL | CONTEXT_INTEGER | CONTEXT_FLOATING_POINT)
            RtlCaptureContext(&cxr)

            _ = SymInitializeW(hProcess, nil, true)
            _ = SymSetOptions(DWORD(SYMOPT_DEFERRED_LOADS | SYMOPT_LOAD_LINES | SYMOPT_UNDNAME))

            var Frame: STACKFRAME64 = STACKFRAME64()
            #if arch(arm)
            Frame.AddrPC.Offset = cxr.Pc
            Frame.AddrFrame.Offset = cxr.R11
            Frame.AddrStack.Offset = cxr.Sp
            #elseif arch(arm64)
            Frame.AddrPC.Offset = cxr.Pc
            Frame.AddrFrame.Offset = cxr.Fp
            Frame.AddrStack.Offset = cxr.Sp
            #elseif arch(i386)
            Frame.AddrPC.Offset = cxr.Eip
            Frame.AddrFrame.Offset = cxr.Ebp
            Frame.AddrStack.Offset = cxr.Esp
            #elseif arch(x86_64)
            Frame.AddrPC.Offset = cxr.Rip
            Frame.AddrFrame.Offset = cxr.Rbp
            Frame.AddrStack.Offset = cxr.Rsp
            #else
            #error("unsupported architecture")
            #endif
            Frame.AddrPC.Mode = AddrModeFlat
            Frame.AddrFrame.Mode = AddrModeFlat
            Frame.AddrStack.Mode = AddrModeFlat

            // Constant indicating the maximum symbol length that we expect
            // during symbolication of the stack trace.
            let kMaxSymbolLength: Int = 255

            // Heap allocate the buffer as we need to account for the trailing
            // storage that we need to provide.
            let pSymbolBuffer: UnsafeMutableRawPointer =
                UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<IMAGEHLP_SYMBOL64>.size + kMaxSymbolLength,
                                                 alignment: 1)
            defer { pSymbolBuffer.deallocate() }

            let pSymbol: UnsafeMutablePointer<IMAGEHLP_SYMBOL64> =
                pSymbolBuffer.bindMemory(to: IMAGEHLP_SYMBOL64.self,
                                         capacity: 1)

            let hThread: HANDLE = GetCurrentThread()
            var toSkip = installedFormat.skip
            while StackWalk64(Backtrace.MachineType, hProcess, hThread,
                              &Frame, &cxr, nil, SymFunctionTableAccess64,
                              SymGetModuleBase64, nil) {
                if toSkip > 0 {
                    toSkip -= 1
                    continue
                }

                var qwModuleBase: DWORD64 =
                    SymGetModuleBase64(hProcess, Frame.AddrPC.Offset)

                let module: String = withUnsafeMutablePointer(to: &qwModuleBase) {
                    $0.withMemoryRebound(to: HINSTANCE.self, capacity: 1) { hInstance in
                        String(decoding: [WCHAR](unsafeUninitializedCapacity: Int(MAX_PATH + 1)) {
                            $1 = Int(GetModuleFileNameW(hInstance.pointee,
                                                        $0.baseAddress,
                                                        DWORD($0.count)))
                        }, as: UTF16.self)
                    }
                }

                pSymbol.pointee.SizeOfStruct =
                    DWORD(MemoryLayout<IMAGEHLP_SYMBOL64>.size)
                pSymbol.pointee.MaxNameLength = DWORD(kMaxSymbolLength)
                _ = SymGetSymFromAddr64(hProcess, Frame.AddrPC.Offset, nil,
                                        pSymbol)

                var symbol: String =
                    withUnsafePointer(to: &pSymbol.pointee.Name) {
                        String(cString: $0)
                    }

                // Undecorate Swift 3+ names only.  Earlier Swift decorations
                // are unsupported.  Any MSVC name decoration has been
                // unperformed during the DbgHelp operation through the use of
                // the `SYMOPT_UNDNAME` option.
                if symbol.hasPrefix("$s") || symbol.hasPrefix("$S") {
                    symbol = _stdlib_demangleName(symbol)
                }

                var Displacement: DWORD = 0
                var Line: IMAGEHLP_LINE64 = IMAGEHLP_LINE64()
                Line.SizeOfStruct = DWORD(MemoryLayout<IMAGEHLP_LINE64>.size)
                _ = SymGetLineFromAddr64(hProcess, Frame.AddrPC.Offset,
                                         &Displacement, &Line)


                #if arch(arm64) || arch(x86_64)
                let formattedPc = String(format: "%#016x", Frame.AddrPC.Offset)
                #else
                let formattedPc = String(format: "%#08x", Frame.AddrPC.Offset)
                #endif

                let demangledFunction: String?
                if !symbol.isEmpty {
                    // Truncate the module path to the filename.  The
                    // `PathFindFileNameW` call will return the beginning of the
                    // string if a path separator character is not found.
                    if let pszModule = module.withCString(encodedAs: UTF16.self,
                                                          PathFindFileNameW) {
                        demangledFunction = "\(String(decodingCString: pszModule, as: UTF16.self))!\(symbol)"
                    } else {
                        demangledFunction = nil
                    }
                } else {
                    demangledFunction = nil
                }

                let file: (fileName: String, line: Int)?
                if let szFileName = Line.FileName {
                    file = (fileName: String(cString: szFileName), line: Int(Line.LineNumber))
                } else {
                    file = nil
                }

                if let line = installedFormat.formatter(formattedPc, demangledFunction, file) {
                    _ = line.withCString { pszDetails in
                        withVaList([pszDetails]) {
                            vfprintf(stderr, "%s", $0)
                        }
                    }
                }
            }

            _ = SymCleanup(hProcess)

            // We have not handled the exception, continue the search.
            return EXCEPTION_CONTINUE_SEARCH
        }
    }
}

#else
public enum Backtrace {
    /// Install the backtrace handler on default signals. Available on Windows and Linux only.
    public static func install(format: Format = .default) {}

    /// Install the backtrace handler on specific signals. Available on Linux only.
    public static func install(signals: [CInt], format: Format = .default) {}

    @available(*, deprecated, message: "This method will be removed in the next major version.")
    public static func print() {}
}
#endif
