import CodingGame;
import List;
using List.ListOps;
using StringTools;
using Math;

final class BrickInTheWall {
  public static function main() {
    final x = CodingGame.readInt();
    final n = CodingGame.readInt();
    final b = CodingGame.readline().split(' ').toList().map(Std.parseInt).sort((x,y) -> y - x);
    

    function work(l: Int, s: List<Int>): Float
      return if (s.isEmpty()) 0.0
             else s.take(x).map(m -> l * 0.65 * m).sumFloat() + work(l + 1, s.drop(x));

    function pad(f: Float): String {
      final r = Std.int((1000 * f).round());
      return '${Std.int(r/1000)}.' + '${r % 1000}'.lpad("0", 3);
    }
    
    Sys.println(pad(work(0,b)));
  }
    
}