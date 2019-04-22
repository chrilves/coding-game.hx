
import Trampoline2;
using Trampoline2.Trampoline2Ops;

final class Tuto {
  public static function fib(n: Int): Trampoline2<Int>
    if (n <= 0)
      return Trampoline2Ops.pure(0);
    else
      return fib.callT(n - 1).map(x -> x + 1);

  static final m = fib(1000000);

  static public function main():Void {
    //Sys.println(m);
    Sys.println(m.run());
  }
    
}