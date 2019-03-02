using Trampoline.TrampolineOps;

enum Trampoline<A> {
  Done(value: A);
  Defer(trampoline: Void -> Trampoline<A>);
  FlatMap<A,B>(eff: Trampoline<A>, cont: A -> Trampoline<B>): Trampoline<B>;
}

final class TrampolineOps {
  inline public static function pure<A>(a:A): Trampoline<A>
    return Done(a);

  inline public static function defer<A>(t: Void -> Trampoline<A>): Trampoline<A>
    return Defer(t);
  
  inline public static function delay<A>(t: Void -> A): Trampoline<A>
    return Defer(() -> Done(t()));

  inline public static function call<A,B>(_this: A, f: A -> B): Trampoline<B>
    return FlatMap(Done(_this), a -> Done(f(a)));

  inline public static function guarded<A,B>(f: A -> Trampoline<B>): A -> Trampoline<B>
    return a -> Defer(() -> f(a));

  public static function run<A>(_this: Trampoline<A>): A {
    var trampo = _this;
    while(true) switch trampo {
      case Done(a):
        return a;
      case Defer(t): 
        trampo = t();
      case FlatMap(Done(a), f):
        trampo = f(a);
      case FlatMap(Defer(t), f):
        trampo = FlatMap(t(), f);
      case FlatMap(FlatMap(u,v),h):
        trampo = FlatMap(u, x -> FlatMap(v(x),h));
    }
  }

  public static function flatMap<A,B>(_this: Trampoline<A>, f: A -> Trampoline<B>): Trampoline<B> {
    var curTrampo:  Trampoline<A> = _this;
    var curFun:A -> Trampoline<B> = f;
    while(true) switch curTrampo {
      case Done(a):
        return Defer(() -> curFun(a));
      case Defer(_):
        return FlatMap(curTrampo, curFun);
      case FlatMap(t,g):
        curTrampo = cast t;
        curFun    = x -> FlatMap(g(cast x), curFun);
    }
  }

  inline public static function map<A,B>(_this: Trampoline<A>, f: A -> B): Trampoline<B>
    return _this.flatMap(a -> Done(f(a)));

  inline public static function ap<A,B>(_this: Trampoline<A->B>, arg: Trampoline<A>): Trampoline<B>
    return _this.flatMap(f -> arg.map(f));
}