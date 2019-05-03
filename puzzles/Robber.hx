
import CodingGame.*;
import List;
import haxe.ds.IntMap;

using List.ListOps;

final class Robber {

  inline public static function max(i: Int, j: Int): Int
    if (i > j) return i else return j;
  
  public static function robber(l: List<Int>): Int
    return switch l {
      case Nil: 0;
      case Cons(hd,tl): max(hd + robber(tl.drop(1)), robber(tl)); 
    };

  public static function robberMemo(l: List<Int>): Int {
    final cache = new IntMap();

    function aux(list: List<Int>): Int {
      final i = list.length();
      return switch cache.get(i) {
        case null:
          final x = switch list {
            case Nil: 0;
            case Cons(hd,tl): max(hd + aux(tl.drop(1)), aux(tl)); 
          };
          cache.set(i, x);
          x;

        case x: x;
      };
    }
      
    return aux(l);
  }
    

  public  static function main() {
    final l =
      ListOps
        .range(1, CodingGame.readInt(), 1)
        .map(_ -> CodingGame.readInt());

    Sys.println(robberMemo(l));
  }
}