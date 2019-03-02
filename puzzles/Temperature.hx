import Parser;

using Parser.ParserOps;
using List.ListOps;

typedef SParser<A> = Parser<String, A>

final class Temperature {
  public static final pnumber: SParser<Int> =
    Parsers.space.between(None, None).ignoreLeft(Parsers.integer);  

  public static final pinput: SParser<List<Int>> =
    pnumber.flatMap(n -> pnumber.between(Some(n), Some(n)));
  
  public inline static function abs(x: Int): Int
    if (x < 0)
      return -x
    else
      return x;
  
  public static final ord: Ordering<Int> =
    Ordering
      .int()
      .cons(Ordering.bool())
      .contraMap(n -> {_1: abs(n), _2: n < 0});

  public static function main() {
    final s1 = Stream.inputChars(Sys.stdin());

    pinput
      .runAsStream(s1, x -> x)
      .map(l ->
        switch (l) {
          case Nil:
            0;
          case Cons(h,t):
            t.foldLeft(h, ord.min);
        }
      )
      .take(1)
      .forEach(i -> Sys.print("" + i + "\n"));
  }
}