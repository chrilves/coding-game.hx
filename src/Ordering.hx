import Prelude;

using HList.HListOps;

enum Ord {
  LT;
  EQ;
  GT;
}

abstract Ordering<A>((A,A) -> Ord) {
  inline public function new(f: (A,A) -> Ord) {
    this = f;
  }

  inline public function compare(x:A, y: A): Ord
    return this(x,y);

  inline public static function fromLT<A>(isLesserThan: (A,A) -> Bool): Ordering<A>
    return new Ordering((x,y) ->
      if (isLesserThan(x,y))
        LT
      else if (isLesserThan(y,x))
        GT
      else
        EQ
    );
  
  inline public function lt(x: A, y: A): Bool
    return this(x,y) == LT;

  inline public function gt(x: A, y: A): Bool
    return this(x,y) == GT;
  
  inline public function eq(x: A, y: A): Bool
    return this(x,y) == EQ;

  inline public function le(x: A, y: A): Bool
    return this(x,y) != GT;

  inline public function ge(x: A, y: A): Bool
    return this(x,y) != LT;

  inline public function ne(x: A, y: A): Bool
    return this(x,y) != EQ;
  
  inline public function min(x: A, y: A): A
    if (le(x,y))
      return x;
    else
      return y;
  
  inline public function max(x: A, y: A): A
    if (ge(x,y))
      return x;
    else
      return y;
  
  inline public function contraMap<B>(f: B -> A): Ordering<B>
    return new Ordering((x,y) -> this(f(x), f(y)));

  inline public function reverse(): Ordering<A>
    return new Ordering((x,y) ->
      switch (this(x,y)) {
        case EQ: EQ;
        case LT: GT;
        case GT: LT;
      }
    );

  inline public function cons<B>(b: Ordering<B>): Ordering<Pair<A,B>>
    return new Ordering((x: Pair<A,B>, y: Pair<A,B>) ->
      switch (this(x._1, y._1)) {
        case EQ: return b.compare(x._2, y._2);
        case n: return n;
      }
    );
  
  inline public function hcons<B>(b: Ordering<HList<B>>): Ordering<HList<Pair<A,B>>>
    return new Ordering((x: HList<Pair<A,B>>, y: HList<Pair<A,B>>) ->
      switch (this(x.head(), y.head())) {
        case EQ: return b.compare(x.tail(), y.tail());
        case n: return n;
      }
    );
  
  inline public static function int(): Ordering<Int>
    return new Ordering((x,y) ->
      if (x < y)
        LT
      else if (x > y)
        GT
      else
        EQ  
    );
  
  inline public static function bool(): Ordering<Bool>
    return new Ordering((x,y) ->
      if (x == y)
        EQ
      else if (x)
        GT
      else
        LT
    );
  
  inline public static function unit(): Ordering<Unit>
    return new Ordering((_,_) -> EQ);
}