import haxe.ds.Either;
import haxe.ds.Option;
import ListF;

using List.ListOps;
using Prelude;

typedef List<A> = ListF<A, List<A>>

final class ListOps {
  public static function foldLeft<A,B>(self: List<A>, z: B, f: (A,B) -> B): B {
    var res = z;
    var l   = self;
    while(true) switch l {
      case Nil:
        return res;
      case Cons(h,t):
        res = f(h, res);
        l   = t;
    }
  }

  public static function unfold<A,B>(seed:A, f: A -> ListF<B,A>): List<B> {
    function aux(s0:A , cont: List<B>): List<B> {
      var k = cont;
      var s = s0;
      while(true) switch f(s) {
        case Nil: return k;
        case Cons(h,t):
          k = Cons(h, k);
          s = t;
      }
    }
    return aux(seed, Nil).reverse();
  }

  public static function forEach<A,B>(_this: List<A>, f: A -> B): Void {
    var l = _this;
    while(true) switch l {
      case Nil: return;
      case Cons(h,t):
        f(h);
        l = t;
    }
  }

  public static function take<A>(_this: List<A>, n: Int): List<A> {
    var list: List<A> = _this;
    var toTake = n;
    var acc: List<A> = Nil;

    while(true)
      if (toTake <= 0)
        return acc.reverse(); 
      else switch list {
        case Nil:
          return acc.reverse();
        case Cons(head, tail):
          list = tail;
          toTake -= 1;
          acc = Cons(head, acc);
      }
  }
  
  public static function drop<A>(_this: List<A>, n: Int): List<A> {
    var list = _this;
    var toDrop = n;

    while(true)
      if (toDrop <= 0)
        return list;
      else switch list {
        case Nil:
          return Nil;
        case Cons(head, tail):
          list = tail;
          toDrop -= 1;
      }
  }

  public static function takeWhile<A>(_this: List<A>, p: A -> Bool): List<A> {
    var list: List<A> = _this;
    var acc : List<A> = Nil;

    while(true) switch list {
      case Nil:
        return acc.reverse();
      case Cons(head, tail):
        if (p(head)) {
          list = tail;
          acc = Cons(head, acc);
        } else return acc.reverse();
    }
  }
  
  public static function dropWhile<A>(_this: List<A>, p: A -> Bool): List<A> {
    var list = _this;
    
    while(true) switch list {
      case Nil:
        return Nil;
      case Cons(head, tail):
        if (p(head)) list = tail;
        else         return list;
    }
  }

  public static function zip<A,B>(_this: List<A>, o: List<B>): List<Pair<A,B>> {
    var l1 = _this;
    var l2 = o;
    var acc: List<Pair<A,B>> = Nil;

    while(true) switch [l1, l2] {
      case [Cons(h1,t1), Cons(h2,t2)]:
        l1 = t1;
        l2 = t2;
        acc = Cons(Prelude.pair(h1,h2), acc);
      case [_, _]:
        return acc.reverse();
    }
  }

  public static function mkString(_this: List<String>, sep: String): String {
    var l = _this;
    var k: List<String> = Nil;

    function step(h: String, s: String): String
      return h + sep + s;

    while(true) switch l {
      case Nil:
        return k.foldLeft("", step);
      case Cons(h, Nil):
        return k.foldLeft(h, step);
      case Cons(h, t):
        l = t;
        k = Cons(h,k);
    }
  }

  public static function length<A>(l: List<A>): Int {
    var tmp = l;
    var acc = 0;
    while(true) switch tmp {
      case Nil:
        return acc;
      case Cons(_,tl):
        acc += 1;
        tmp  = tl;
    }
  }

  inline public static function pure<A>(a: A): List<A>
    return Cons(a, Nil);

  inline public static function cons<A>(head: A, tail: List<A>): List<A>
    return Cons(head, tail);
  
  inline public static function isEmpty<A>(_this: List<A>): Bool
    return _this == Nil;
  
  inline public static function range(from: Int, to: Int, step: Int): List<Int> {
    final doesContinue =
      if (step > 0) i -> i <= to
      else          i -> i >= to;
    
    return unfold(from, i -> if (doesContinue(i)) Cons(i, i + step) else Nil);
  }

  inline public static function reverse<A>(self: List<A>): List<A>
    return self.foldLeft(Nil, cons);

  inline public static function fold<A,B>(self: List<A>, z: B, f: (A,B) -> B): B
    return self.reverse().foldLeft(z,f);

  inline public static function foldF<A,B>(_this: List<A>, f: ListF<A,B> -> B): B
    return _this.fold(f(Nil), (a,b) -> f(Cons(a,b)));
    
  inline public static function foldLeftMonoid<A>(_this: List<A>, m: Monoid<A>): A
    return _this.foldLeft(m.zero, m.combine);

  inline public static function foldMonoid<A>(_this: List<A>, m: Monoid<A>): A
    return _this.fold(m.zero, m.combine);

  inline public static function append<A>(_this: List<A>, l: List<A>): List<A>
    return _this.fold(l, Cons);
  
  inline public static function map<A,B>(self: List<A>, f: A -> B): List<B>
    return self.foldLeft(Nil, (h,l:List<B>) -> Cons(f(h),l)).reverse();

  inline public static function flatMap<A,B>(_this: List<A>, f: A -> List<B>): List<B>
    return _this.fold((Nil: List<B>), (a,l) -> f(a).append(l));
  
  inline public static function ap<A,B>(_this: List<A -> B>, la: List<A>): List<B>
    return _this.flatMap(f -> la.map(f));

  inline public static function filter<A>(_this: List<A>, p: A -> Bool): List<A>
    return _this.fold(Nil, (head, tail: List<A>) ->
      if (p(head))
        Cons(head, tail)
      else
        tail
    );

  inline public static function mapFilter<A,B>(_this: List<A>, p: A -> Option<B>): List<B>
    return _this.fold(Nil, (head, tail: List<B>) -> switch p(head) {
      case Some(b): Cons(b, tail);
      case None:    tail;
    });

  inline public static function forall<A>(_this: List<A>, p: A -> Bool): Bool
    return _this.dropWhile(p).isEmpty();

  inline public static function exists<A>(_this: List<A>, p: A -> Bool): Bool
    return !(_this.forall(a -> !p(a)));

  inline public static function sort<T>(_this: List<T>, f: (T,T) -> Int): List<T> {
    final arr = _this.toArray();
    arr.sort(f);
    return arr.toList();
  }

  inline public static function toList<A>(_this: Array<A>): List<A>
    return unfold(_this.iterator(), i -> if (i.hasNext()) Cons(i.next(), i) else Nil);

  inline public static function toArray<A>(_this: List<A>): Array<A> {
    final arr = new Array<A>();
    _this.forEach(arr.push);
    return arr;
  }
  
  public static inline function toStream<A>(_this: List<A>): Stream<A>
    return Stream.unfold(_this, x -> x);

  inline public static function sumInt(_this: List<Int>): Int
    return _this.foldLeft(0, (x,y) -> x + y);

  inline public static function sumFloat(_this: List<Float>): Float
    return _this.foldLeft(0.0, (x,y) -> x + y);
}