import Prelude;
import List;
using List.ListOps;

final class CreditCard {

  public static function check(l: List<Int>) {
    final phase2 =
       l.fold(
          Prelude.pair(false, (Nil: List<Int>)),
          (i, p) -> Prelude.pair(!p._1, if (p._1) Cons(i, p._2) else p._2)
        )
        ._2
        .map(n -> 2 * n)
        .map(n -> if (n >= 10) n - 9 else n)
        .sum();
        
    final phase3 =
      l.fold(
        Prelude.pair(true, 0),
        (i, s) -> Prelude.pair(!s._1, if (s._1) i + s._2 else s._2)
      )._2;
    
    return
      if ((phase2 + phase3) % 10 == 0)
        "YES"
      else
        "NO";
  }

  public static function main() {
    ListOps.range(1, CodingGame.readInt(), 1)
           .forEach(_ -> Sys.println(check(CodingGame.readline()
                                                     .split("")
                                                     .toList()
                                                     .filter(s -> !Prelude.isWhitespace(s))
                                                     .map(Std.parseInt)
                                          )
                                    )
           );
  }
}