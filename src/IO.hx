using IO.IOOps;

enum IO<A> {
  Done(value: A);
  Defer(io: Void -> IO<A>);
  FlatMap<A,B>(eff: IO<A>, cont: A -> IO<B>): IO<B>;
}

final class IOOps {
  inline public static function pure<A>(a:A): IO<A>
    return Done(a);

  inline public static function defer<A>(t: Void -> IO<A>): IO<A>
    return Defer(t);
  
  inline public static function delay<A>(t: Void -> A): IO<A>
    return Defer(() -> Done(t()));

  inline public static function call<A,B>(_this: A, f: A -> B): IO<B>
    return FlatMap(Done(_this), a -> Done(f(a)));

  inline public static function guarded<A,B>(f: A -> IO<B>): A -> IO<B>
    return a -> Defer(() -> f(a));
  
  public static function run<A>(_this: IO<A>): A {
    var io = _this;
    while(true) switch io {
      case Done(a):
        return a;
      case Defer(t): 
        io = t();
      case FlatMap(Done(a), f):
        io = f(a);
      case FlatMap(Defer(t), f):
        io = FlatMap(t(), f);
      case FlatMap(FlatMap(u,v),h):
        io = FlatMap(u, x -> FlatMap(v(x),h));
    }
  }

  public static function flatMap<A,B>(_this: IO<A>, f: A -> IO<B>): IO<B> {
    var curIO:  IO<A> = _this;
    var curFun:A -> IO<B> = f;
    while(true) switch curIO {
      case Done(a):
        return Defer(() -> curFun(a));
      case Defer(_):
        return FlatMap(curIO, curFun);
      case FlatMap(t,g):
        curIO = cast t;
        curFun    = x -> FlatMap(g(cast x), curFun);
    }
  }

  inline public static function map<A,B>(_this: IO<A>, f: A -> B): IO<B>
    return _this.flatMap(a -> Done(f(a)));

  inline public static function ap<A,B>(_this: IO<A->B>, arg: IO<A>): IO<B>
    return _this.flatMap(f -> arg.map(f));

  inline public 
}