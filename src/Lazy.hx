import haxe.ds.Either;
import Trampoline;

using Trampoline.TrampolineOps;

final class Lazy<A> {
  private var value: Either<Trampoline<A>, A>;
  
  inline private function new(v: Either<Trampoline<A>, A>)
    value = v;

  public function force(): A
    switch (value) {
      case Right(a):
        return a;
      case Left(t):
        final tmp = t.run();
        value = Right(tmp);
        return tmp;
    }

  public inline function map<B>(g: A -> B): Lazy<B>
    return new Lazy(switch value {
      case Right(a): Right(g(a));
      case Left(t): Left(t.map(g));
    });

  public inline function flatMap<B>(g: A -> Lazy<B>): Lazy<B>
    switch value {
      case Right(a):
        return g(a);
      case Left(t):
        return new Lazy(Left(t.flatMap(a -> switch g(a).value {
          case Left(u): u;
          case Right(v): Trampoline.Done(v);
        })));
    }

    
  public static inline function pure<A>(a:A): Lazy<A>
    return new Lazy(Right(a));
  
  public static inline function delay<A>(f: Void -> A): Lazy<A>
    return new Lazy(Left(TrampolineOps.delay(f)));
}

final class LazyOps {
  public static inline function ap<A,B>(_this: Lazy<A -> B>, fa: Lazy<A>): Lazy<B>
    return _this.flatMap(f -> fa.map(f));
}