import Prelude;
import haxe.ds.Option;
import ListF;

using Parser.ParserOps;
using List.ListOps;
using OptionOps;

enum Parser<C,A> {
  Get<C>: Parser<C,C>;
  Fail<C,A>: Parser<C,A>;
  Or<C,A>(first: Parser<C,A>, second: Parser<C,A>): Parser<C,A>;
  Not<C,A>(parser: Parser<C,A>): Parser<C,Unit>;
  Pure<C,A>(value: A): Parser<C,A>;
  FlatMap<C,A,B>(parser: Parser<C,A>, f: A -> Parser<C,B>): Parser<C,B>;
}

final class ParserOps {
  public static inline function pure<C,A>(a: A): Parser<C,A>
    return Pure(a);

  public static inline function get<C>(): Parser<C,C>
    return Get;

  public static function flatMap<C,A,B>(_this: Parser<C,A>, f: A -> Parser<C,B>): Parser<C,B>
    switch (_this) {
      case Pure(a):
        return f(a);
      case Fail:
        return Fail;
      case FlatMap(p, g):
        return flatMap(p, x -> g(x).flatMap(f));
      case _:
        return FlatMap(_this, f);
    }
  
  public static inline function or<C,A>(_this: Parser<C,A>, p: Parser<C,A>): Parser<C,A>
    switch (_this) {
      case Pure(a):
        return _this;
      case Fail:
        return p;
      case Or(f,s):
        return f.or(s.or(p));
      case _:
        return Or(_this, p);
    }

  public static inline function map<C,A,B>(_this: Parser<C,A>, f: A -> B): Parser<C,B>
    return _this.flatMap(a -> Pure(f(a)));

  public static inline function ap<C,A,B>(pf: Parser<C,A -> B>, pa: Parser<C,A>): Parser<C,B>
    switch [pf, pa] {
      case [Pure(f), Pure(a)]:
        return Pure(f(a));
      case [Fail, _]:
        return Fail;
      case [_, Fail]:
        return Fail;
      case [_,_]:
        return pf.flatMap(f -> pa.map(f));
    }
  
  public static inline function not<C,A>(_this: Parser<C,A>): Parser<C,Unit>
    switch (_this) {
      case Pure(_):
        return Fail;
      case Fail:
        return Pure(Unit);
      case Not(v):
        return v.map(_ -> Unit);
      case Or(f,s):
        return f.not().flatMap(_ -> not(s));
      case _:
        return Not(_this);
    }
  
  public static inline function filter<C,A>(_this: Parser<C,A>, p: A -> Bool): Parser<C, A>
    return _this.flatMap(v ->
      if (p(v))
        pure(v)
      else
        Fail
    );

  public static inline function mapFilter<C,A,B>(_this: Parser<C,A>, p: A -> Option<B>): Parser<C, B>
    return _this.flatMap(v ->
      switch (p(v)) {
        case Some(b): pure(b);
        case None: Fail;
      }
    );  

  public static function between<C,A>(_this: Parser<C,A>, min: Option<Int>, max: Option<Int>): Parser<C, List<A>> {
    final v =
      switch (max) {
        case Some(b):
          {isFailed: (b < 0) || switch (min) {
                       case Some(a): a > b;
                       case None: false;
                     },
           isEnough: b == 0
          }
        case None:
          {isFailed: false, isEnough: false}
      };
    
    if (v.isFailed)
      return Fail;
    else if (v.isEnough)
      return Pure(Nil)
    else
      return _this
                .flatMap(h -> _this.between(min.map(x -> x - 1), max.map(x -> x - 1))
                                   .map(l -> Cons(h,l))
                        )
                .or(if (min.fold(x -> x <= 0, true)) Pure(Nil) else Fail);
  }

  public static inline function ignoreLeft<C,A,B>(_this: Parser<C,A>, p: Parser<C,B>): Parser<C,B>
    return flatMap(_this, _ -> p);

  public static inline function ignoreRight<C,A,B>(_this: Parser<C,A>, p: Parser<C,B>): Parser<C,A>
    return flatMap(_this, a -> map(p, _ -> a));

  public static function runStream<C,A>(p: Parser<C,A>, stream: Stream<C>): ListF<A,Stream<C>>
    switch (p) {
      case Get:
        return stream.run();
      
      case Pure(a):
        return Cons(a, stream);
      
      case Fail:
        return Nil;
      
      case Not(p2):
        switch (runStream(p2, stream)) {
          case Nil:
            return Cons(Unit, stream);
          case Cons(_,_):
            return Nil;
        }

      case Or(f,s):
        switch (runStream(f,stream)) {
          case Nil:
            return runStream(s,stream);
          case v:
            return v;
        }

      case FlatMap(p2, f):
        switch (runStream(p2, stream)) {
          case Nil:
            return Nil;
          case Cons(value, seed):
            return runStream(f(value), seed);
        }
    }
  
  inline public static function runAsStream<C,A>(p: Parser<C,A>, stream: Stream<C>, f: Stream<C> -> Stream<C>): Stream<A>
    return Stream.unfold(f(stream), s -> ListFOps.map2(runStream(p, s), f));
}

final class Parsers {
  public static inline function isSpace(s: String): Bool
    return s == " " || s == "\t" || s == "\n" || s == "\r";

  public static final space: Parser<String, String> =
    Get.filter(isSpace);

  public static final sign: Parser<String, Int> =
    Get.mapFilter(c ->
        switch(c) {
          case "+": Some(1);
          case "-": Some(-1);
          case _: None;
        }
      ).or(Pure(1));

  public static final digit: Parser<String, Int> =
    Get.mapFilter((l:String) -> {
      final c = l.charCodeAt(0);
      if (c >= "0".code && c <= "9".code)
        Some(c - "0".code)
      else
        None;
    });

  public static final integer: Parser<String, Int> =
    Pure((sign:Int) -> (digits: List<Int>) ->
            sign * digits.foldLeft(0, (r,c) -> 10*r + c)
        )
      .ap(sign)
      .ap(digit.between(Some(1), None));
}