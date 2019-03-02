import haxe.ds.Either;

enum Unit {
  Unit;
}

typedef Pair<A,B> = {_1: A, _2: B}

final class Prelude {

  inline public static function pair<A,B>(one:A, two: B): Pair<A,B>
    return {_1: one, _2: two};

  public static function rec<A,B>(_this: A, f: A -> Either<B,A>): B {
    var state = _this;
    while(true) switch f(state) {
      case Left(b):
        return b;
      case Right(a):
        state = a;
    }
  }

  inline public static function isWhitespace(s: String): Bool
    return StringTools.trim(s) == "";
}