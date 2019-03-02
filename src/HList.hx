import Prelude;

enum HList<T> {
  HNil: HList<Unit>;
  HCons<H,T>(head: H, tail: HList<T>): HList<Pair<H,T>>; 
}

final class HListOps {
  public static inline function head<A,B>(_this: HList<Pair<A,B>>): A
    switch (_this) {
      case HCons(h,_): return h;
    }
  
  public static inline function tail<A,B>(_this: HList<Pair<A,B>>): HList<B>
    switch (_this) {
      case HCons(_, t): return t;
    }
}