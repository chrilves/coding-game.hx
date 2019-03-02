import haxe.ds.Option;

using OptionOps;

final class OptionOps {
  inline public static function fold<A,B>(_this: Option<A>, f: A -> B, v: B): B
    switch (_this) {
      case Some(x): return f(x);
      case None: return v;
    }

  inline public static function getOrElse<A>(_this: Option<A>, dft: A): A
    switch (_this) {
      case Some(v): return v;
      case None: return dft;
    }
  
  inline public static function orElse<A>(_this: Option<A>, dft: Option<A>): Option<A>
    switch (_this) {
      case Some(_): return _this;
      case None: return dft;
    }

  inline public static function flatMap<A,B>(_this: Option<A>, f: A -> Option<B>): Option<B>
    switch (_this) {
      case Some(v): return f(v);
      case None: return None;
    }
  
  inline public static function map<A,B>(_this: Option<A>, f: A -> B): Option<B>
    return _this.flatMap(x -> Some(f(x)));

  inline public static function ap<A,B>(_this: Option<A -> B>, o: Option<A>): Option<B>
    return _this.flatMap(f -> o.map(f));
}