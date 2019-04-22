enum IO<A> {
  Pure(value: A);
  Defer(trampoline: Void -> IO<A>): IO<A>;
  Ap<A,B>(fun: IO<A -> B>, arg: IO<A>): IO<B>;
  Flat(tower: IO<IO<A>>): IO<A>;
}

private enum ContRun<A,B> {
  Id: ContRun<A,A>;
  ApFun<A,B,C>(arg: IO<A>, cont: ContRun<B,C>): ContRun<A -> B, C>;
  ApArg<A,B,C>(fun: A -> B, cont: ContRun<B,C>): ContRun<A,C>;
  FlatK(cont: ContRun<IO<A>, B>): ContRun<A,B>;
}

final class IOOps {
  inline public static function pure<A>(a:A): IO<A>
    return Pure(a);

  inline public static function defer<A>(t: Void -> IO<A>): IO<A>
    return Defer(t);
  
  inline public static function delay<A>(t: Void -> A): IO<A>
    return Defer(() -> Pure(t()));

  inline public static function call<A,B>(_this: A -> B, a: A): IO<B>
    return Defer(() -> Pure(_this(a)));

  inline public static function apply<A,B>(_this: A, f: A -> B): IO<B>
    return Defer(() -> Pure(f(_this)));

  inline public static function callT<A,B>(_this: A -> IO<B>, a: A): IO<B>
    return Defer(() -> _this(a));

  inline public static function applyT<A,B>(_this: A, f: A -> IO<B>): IO<B>
    return Defer(() -> f(_this));

  inline public static function ap<A,B>(_this: IO<A -> B>, ta: IO<A>): IO<B>
    return switch [_this, ta] {
      case [Pure(f), Pure(a)]: Pure(f(a));
      case [_,_]: Ap(_this, ta);
    }
  
  inline public static function map<A,B>(_this: IO<A>, f: A -> B): IO<B>
    return ap(Pure(f), _this);

  inline public static function flattten<A>(_this: IO<IO<A>>): IO<A>
    return switch _this {
      case Pure(m): m;
      case _: Flat(_this);
    };

  inline public static function flatMap<A,B>(_this: IO<A>, f: A -> IO<B>): IO<B>
    return switch _this {
      case Pure(a): f(a);
      case _:  Flat(Ap(Pure(f), _this));
    };

  public static function run<A>(_this: IO<A>): A {
    var trampoline : IO<A> = _this;
    var cont       : ContRun<A,A>  = Id;

    while(true) switch trampoline {
      case Pure(a):
        while(true) switch cont {
          case Id:
            return a;
          case ApFun(arg,k):
            trampoline = cast arg;
            cont       = ApArg(cast a, k);
            break;
          case ApArg(fun,k):
            cont = cast k;
            a    = cast fun(a);
          case FlatK(k):
            trampoline = cast a;
            cont       = cast k;
            break;
        }
      case Defer(f):
        trampoline = f();
      case Ap(fun, arg):
        trampoline = cast fun;
        cont       = cast ApFun(arg, cont);
      case Flat(m): 
        trampoline = cast m;
        cont       = FlatK(cast cont);
    }
  }
}