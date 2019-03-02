using Tuto.ListMethods;
import Sys;

enum List<A> {
  Nil;
  Cons(head: A, tail: List<A>);
}

class ListMethods {
  public static function map<A,B>(_this: List<A>, f: A -> B): List<B>
    switch (_this) {
      case Nil:
        return Nil;
      case Cons(head, tail):
        return Cons(f(head), map(tail, f));
    }

  public static function append<A>(_this: List<A>, l: List<A>): List<A>
    switch (_this) {
      case Nil:
        return l;
      case Cons(head, tail):
        return Cons(head, append(tail, l));
    }

  public static function flatMap<A,B>(_this: List<A>, f: A -> List<B>): List<B>
    switch (_this) {
      case Nil:
        return Nil;
      case Cons(head, tail):
        return append(f(head), flatMap(tail, f));
    }
}

class Tuto {
  static public function main():Void {
    var a = Cons(1, Cons(2, Nil));
    Sys.println(
      ListMethods.map(a, i -> i + 1)
    );
    Sys.println(
      a.map(i -> i + 1)
    );

    Sys.println(
      a.flatMap(i -> Cons(i, Cons(-i, Nil)))
    );
  }
}

enum Parser<A> {
  GetChar: Parser<String>;
  Ou<A>(premier: Parser<A>, second: Parser<A>): Parser<A>;
  Pure<A>(valeur: A): Parser<A>;
  FlatMap<A,B>(p: Parser<A>, f: A -> Parser<B>): Parser<B>;
}