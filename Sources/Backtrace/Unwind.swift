#if os(macOS)

import CLibUnwind

extension Backtrace {
  
  public static func install() {
      self.setupHandler(signal: SIGILL) { _ in
        Backtrace._print()
      }
  }
  
  @available(*, deprecated, message: "This method will be removed in the next major version.")
  public static func print() {
    _print()
  }
  
  private static func _print() {
    var context = unw_context_t()
    guard unw_getcontext(&context) == 0 else {
      #warning("error")
      return
    }
    
    var cursor = unw_cursor_t()
    guard unw_init_local(&cursor, &context) == 0 else {
      #warning("error")
      return
    }
    
    while true {
      let result = unw_step(&cursor)
      guard result >= 0 else {
        #warning("error")
        continue
      }
      
      var pc: UInt = 0
      guard unw_get_reg(&cursor, unw_regnum_t(UNW_REG_IP), &pc) == 0 else {
        #warning("error")
        continue
      }
      
      let function: String?
      
      if #available(macOS 11.0, *) {
        var offset: UInt = 0
        function = String(
          unsafeUninitializedCapacity: 1 << 10,
          initializingUTF8With: { buffer in
            buffer.withMemoryRebound(to: Int8.self) { buffer in
              guard unw_get_proc_name(&cursor, buffer.baseAddress, buffer.count, &offset) == 0 else {
                #warning("error")
                return 0
              }
              return strnlen(buffer.baseAddress!, buffer.count)
            }
          })
      } else {
        function = nil
      }

      printFrame(pc, filename: nil, lineno: 0, function: function)
      
      if result == 0 {
        break
      }
    }
    
  }

  private static func setupHandler(signal: Int32, handler: @escaping @convention(c) (CInt) -> Void) {
      typealias sigaction_t = sigaction
      let sa_flags = CInt(SA_NODEFER) | CInt(bitPattern: CUnsignedInt(SA_RESETHAND))
      var sa = sigaction_t(__sigaction_u: __sigaction_u(__sa_handler: handler),
                           sa_mask: sigset_t(),
                           sa_flags: sa_flags)
      withUnsafePointer(to: &sa) { ptr -> Void in
          sigaction(signal, ptr, nil)
      }
  }
}
#endif
