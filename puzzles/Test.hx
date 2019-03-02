import List;
using List.ListOps;

final class Test {
  public static function main() {
    final l = Cons(1,Cons(2, Cons(3, Cons(4, Cons(5, Cons(6, Nil))))));
    Sys.println(l.take(3));
    Sys.println(l.drop(2));
    Sys.println(l.takeWhile(i -> i < 5));
    Sys.println(l.dropWhile(i -> i < 5));
    Sys.println(l.take(3).zip(l.drop(3)));
    final l2 = [17,12,6,1,4,3,18,5,2,77];
    Sys.println(l2);
    Sys.println(l2.toList().sort((x,y) -> x - y));
  }
}