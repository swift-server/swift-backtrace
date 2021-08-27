import Foundation
import Backtrace

let reason = CommandLine.arguments.count == 2 ? CommandLine.arguments[1] : "unknown"

Backtrace.install()

func A1() -> Void {
    A2()
}

func A2() -> Void {
    A3()
}

func A3() -> Void {
    B1()
}

func B1() -> Void {
    B2()
}

func B2() -> Void {
    B3()
}

func B3() -> Void {
    Van().drive()
}

class Van {
    func drive() -> Void {

        print("\n\n\n")
        print("👇👇👇 case1 :  print current")
        print(Backtrace.current)
        print("\n\n\n")
        print("👇👇👇👇👇 case2 : Backtrace.capture")
        do {
            try Backtrace.capture(from: oilEmpty)
            //fatalError("Backtrace.capture(from: oilEmpty)")
        } catch let err as Backtrace.Captured {
            print(err)
        } catch let Backtrace.Captured.error(err, bt) {
            print(err)
            if !bt.frames.isEmpty {
                print(bt)
            }
        } catch let uncaughtError {
            print("uncaught exception \(uncaughtError)")
        }
        print("\n\n\n")
        print("👇👇👇👇👇👇👇👇👇  case3 : fatalError")
        fatalError(reason)
        print("👆👆👆👆👆👆👆👆👆  note: never print this line !!!")
    }

    func oilEmpty() throws -> Void {
        1 + 1;
        throw CarError.oilEmpty(message: "!!! oil empty !!!")
    }
}

enum CarError: Error {
    case oilEmpty(message: String)
    case flatTire(message: String)
}

A1()


