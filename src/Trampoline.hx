enum Trampoline<A> {
  Pure(value: A);
  Defer(trampoline: Void -> Trampoline<A>): Trampoline<A>;
  Ap<A,B>(fun: Trampoline<A -> B>, arg: Trampoline<A>): Trampoline<B>;
  Flat(tower: Trampoline<Trampoline<A>>): Trampoline<A>;
}

private enum ContRun<A,B> {
  Id: ContRun<A,A>;
  ApFun<A,B,C>(arg: Trampoline<A>, cont: ContRun<B,C>): ContRun<A -> B, C>;
  ApArg<A,B,C>(fun: A -> B, cont: ContRun<B,C>): ContRun<A,C>;
  FlatK(cont: ContRun<Trampoline<A>, B>): ContRun<A,B>;
}

final class TrampolineOps {
  inline public static function pure<A>(a:A): Trampoline<A>
    return Pure(a);

  inline public static function defer<A>(t: Void -> Trampoline<A>): Trampoline<A>
    return Defer(t);
  
  inline public static function delay<A>(t: Void -> A): Trampoline<A>
    return Defer(() -> Pure(t()));

  inline public static function call<A,B>(_this: A -> B, a: A): Trampoline<B>
    return Defer(() -> Pure(_this(a)));

  inline public static function apply<A,B>(_this: A, f: A -> B): Trampoline<B>
    return Defer(() -> Pure(f(_this)));

  inline public static function callT<A,B>(_this: A -> Trampoline<B>, a: A): Trampoline<B>
    return Defer(() -> _this(a));

  inline public static function applyT<A,B>(_this: A, f: A -> Trampoline<B>): Trampoline<B>
    return Defer(() -> f(_this));

  inline public static function call2<A,B,C>(_this: (A,B) -> C, a: A, b:B): Trampoline<C>
    return Defer(() -> Pure(_this(a,b)));

  inline public static function call2T<A,B,C>(_this: (A,B) -> Trampoline<C>, a: A, b: B): Trampoline<C>
    return Defer(() -> _this(a,b));

  inline public static function ap<A,B>(_this: Trampoline<A -> B>, ta: Trampoline<A>): Trampoline<B>
    return switch [_this, ta] {
      case [Pure(f), Pure(a)]: Pure(f(a));
      case [_,_]: Ap(_this, ta);
    }
  
  inline public static function map<A,B>(_this: Trampoline<A>, f: A -> B): Trampoline<B>
    return ap(Pure(f), _this);

  inline public static function flattten<A>(_this: Trampoline<Trampoline<A>>): Trampoline<A>
    return switch _this {
      case Pure(m): m;
      case _: Flat(_this);
    };

  inline public static function flatMap<A,B>(_this: Trampoline<A>, f: A -> Trampoline<B>): Trampoline<B>
    return switch _this {
      case Pure(a): f(a);
      case _:  Flat(Ap(Pure(f), _this));
    };

  public static function run<A>(_this: Trampoline<A>): A {
    var trampoline : Trampoline<A> = _this;
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