import Prelude;
import haxe.ds.Option;
import ListF;
import Trampoline;

using Parser.ParserOps;
using List.ListOps;
using ListF.ListFOps;
using OptionOps;
using Trampoline.TrampolineOps;

private enum Parser<C,A> {
  Pure<C,A>(value: A): Parser<C,A>;
  Ap<C,A,B>(fun: Parser<C, A -> B>, arg: Parser<C, A>): Parser<C,B>;
  Flatten<C,A>(parser: Parser<C,Parser<C,A>>): Parser<C,A>;

  Get<C>: Parser<C,C>;
  Fail<C,A>: Parser<C,A>;
  Or<C,A>(first: Parser<C,A>, second: Parser<C,A>): Parser<C,A>;
}

final class ParserOps {
  public inline static function pure<C,A>(a: A): Parser<C,A>
    return Pure(a);

  public inline static function get<C>(): Parser<C,C>
    return Get;

  public inline static function fail<C,A>(): Parser<C,A>
    return Fail;

  public static function ap<C,A,B>(pf: Parser<C,A -> B>, pa: Parser<C,A>): Parser<C,B>
    return switch [pf, pa] {
      case [Pure(f), Pure(a)]: Pure(f(a));
      case [Fail, _]: Fail;
      case [_, Fail]: Fail;
      case [_,_]: Ap(pf, pa);
    }

  public static function or<C,A>(_this: Parser<C,A>, p: Parser<C,A>): Parser<C,A>
    return switch [_this, p] {
      case [Fail, _]: p;
      case [_, Fail]: _this;
      case [Pure(_),_]: _this;
      case [_,_]: Or(_this, p);
    };
    
  public static function flatten<C,A>(_this: Parser<C,Parser<C,A>>): Parser<C,A>
    return switch _this {
      case Pure(m): m;
      case Fail: Fail;
      case _: Flatten(_this);
    };

  public inline static function map<C,A,B>(_this: Parser<C,A>, f: A -> B): Parser<C,B>
    return ap(pure(f), _this);

  public inline static function flatMap<C,A,B>(_this: Parser<C,A>, f: A -> Parser<C,B>): Parser<C,B>
    return flatten(ap(pure(f), _this));
  
  public inline static function not<C,A>(_this: Parser<C,A>): Parser<C,Unit>
    return or(map(_this, x -> Unit), pure(Unit));
  
  public inline static function filter<C,A>(_this: Parser<C,A>, p: A -> Bool): Parser<C, A>
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

  public static function runStream<C,A>(p: Parser<C,A>, stream: Stream<C>): ListF<A,Stream<C>> {
    
    function aux<D,X>(p2: Parser<D,X>, str: Stream<D>): Trampoline<ListF<X,Stream<D>>>
      return switch p2 {
        case Pure(a):
          TrampolineOps.pure(Cons(a, str));

        case Get:
          TrampolineOps.pure(str.run());
        
        case Fail:
          TrampolineOps.pure(Nil);

        case Ap(f,x):
          aux.call2T(f, str).flatMap(r -> switch r {
            case Nil:
              TrampolineOps.pure(Nil);
            case Cons(hf,tf):
              aux.call2T(x, tf).map(y -> y.map1(hf));
          });

        case Or(f,s):
          aux.call2T(f,str).flatMap(r -> switch  r {
            case Nil: aux.call2T(s,str);
            case v  : TrampolineOps.pure(v);
          });

        case Flatten(x):
          aux.call2T(x, str).flatMap(r -> switch r {
            case Nil: TrampolineOps.pure(Nil);
            case Cons(h,t): aux.call2T(h, t);
          });
      };

    return aux(p, stream).run();
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