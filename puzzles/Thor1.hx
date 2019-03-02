using Stream.StreamMethods;

enum Direction {
  N;
  NE;
  E;
  SE;
  S;
  SW;
  W;
  NW;
}

typedef Point = {x: Int, y: Int}

final class Thor1 {
  public static function direction(dst: Point, src: Point): ListF<Direction, Point>
    switch(Ordering.int().compare(src.x, dst.x)) {
      case LT:
        switch(Ordering.int().compare(src.y, dst.y)) {
          case LT:
            return Cons(SE, {x: src.x + 1, y: src.y + 1});
          case EQ:
            return Cons(E, {x: src.x + 1, y: src.y});
          case GT:
            return Cons(NE, {x: src.x + 1, y: src.y - 1});
        }
      case EQ:
        switch(Ordering.int().compare(src.y, dst.y)) {
          case LT:
            return Cons(S, {x: src.x, y: src.y + 1});
          case EQ:
            return Nil;
          case GT:
            return Cons(N, {x: src.x, y: src.y - 1});
        }
      case GT:
        switch(Ordering.int().compare(src.y, dst.y)) {
          case LT:
            return Cons(SW, {x: src.x - 1, y: src.y + 1});
          case EQ:
            return Cons(W, {x: src.x - 1, y: src.y});
          case GT:
            return Cons(NW, {x: src.x - 1, y: src.y - 1});
        }
    }

  public static function path(dst: Point, src: Point): List<Direction>
    return ListMethods.unfold(src, (s:Point) -> direction(dst, s));

  public static function main() {
    final input: Stream<Int> =
      Parsers
        .integer
        .runAsStream(
          Stream.inputChars(Sys.stdin()),
          s -> s.dropWhile(Parsers.isSpace)
        );
    
    final point: Parser<Int, Point> =
      Pure(x -> y -> {x: x, y: y})
        .ap(Get)
        .ap(Get);
    
    final dirs: Parser<Int, List<Direction>> =
      Pure(d -> s -> path(d,s))
        .ap(point)
        .ap(point);
    
    switch (dirs.runStream(input)) {
      case Nil:
        Sys.println("Error: Bad Input");
      case Cons(l, s):
        s.zip(l.toStream()).forEach(i -> Sys.println(i._2));
    }
  }
}