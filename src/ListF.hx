using ListF.ListFOps;

enum ListF<A,R> {
  Nil;
  Cons(head:A, tail: R);
}

final class ListFOps {
  inline public static function biMap<A,R,B,S>(_this: ListF<A,R>, f: A -> B, g: R -> S): ListF<B,S>
    switch (_this) {
      case Nil: return Nil;
      case Cons(head, tail): return Cons(f(head), g(tail));
    }
  
  inline public static function map1<A,R,B>(_this: ListF<A,R>, f: A -> B): ListF<B,R>
    return _this.biMap(f, x -> x);

  inline public static function map2<A,R,S>(_this: ListF<A,R>, f: R -> S): ListF<A,S>
    return _this.biMap(x -> x, f);
}