import List;
using List.ListOps;

final class Rugby {
  inline public static function min(a: Int, b: Int): Int
    if (a <= b) return a; else return b;

  public static function main() {
    final n = Std.parseInt(CodingGame.readline());
    
    final l =
      ListOps.range(0, Std.int(n / 5), 1).flatMap(tries -> {
        final n1 = n - 5*tries;
        ListOps.range(0, min(Std.int(n1 / 2), tries), 1).flatMap(transfo -> {
          final n2 = n1 - 2*transfo;
          if (n2 % 3 == 0) ListOps.pure({tries: tries, transfo: transfo, kick: Std.int(n2 / 3)})
          else             Nil;
        });
      });
    l.forEach(x -> Sys.println('${x.tries} ${x.transfo} ${x.kick}'));
  }
}