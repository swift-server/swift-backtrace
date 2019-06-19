#if os(Linux)
import Glibc
import CBacktrace

public enum Backtrace {
    public static func install() {
        setupHandler(signal: SIGILL) { _ in
            // this is all undefined behaviour, not allowed to malloc or call backtrace here...
            let maxFrames = 50
            let stackSymbols: UnsafeMutableBufferPointer<UnsafeMutableRawPointer?> = .allocate(capacity: maxFrames)
            stackSymbols.initialize(repeating: nil)
            let howMany = backtrace(stackSymbols.baseAddress!, CInt(maxFrames))
            let ptr = backtrace_symbols(stackSymbols.baseAddress!, howMany)
            let realAddresses = Array(UnsafeBufferPointer(start: ptr, count: Int(howMany))).compactMap { $0 }
            realAddresses.forEach {
                fputs($0, stderr)
            }
        }
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
#else
public enum Backtrace {
    public static func install() { 
    }
}
#endif
