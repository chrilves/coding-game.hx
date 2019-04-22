import List;
using List.ListOps;

final class Rubik {
  public static function rot(r: String, f: String): String
    return switch [r, f] {
      case ["x", "R"]: "R";
      case ["x", "L"]: "L";
      case ["x", "F"]: "U";
      case ["x", "U"]: "B";
      case ["x", "B"]: "D";
      case ["x", "D"]: "F";

      case ["x'", "R"]: "R";
      case ["x'", "L"]: "L";
      case ["x'", "F"]: "D";
      case ["x'", "D"]: "B";
      case ["x'", "B"]: "U";
      case ["x'", "U"]: "F";

      case ["y", "U"]: "U";
      case ["y", "D"]: "D";
      case ["y", "F"]: "L";
      case ["y", "L"]: "B";
      case ["y", "B"]: "R";
      case ["y", "R"]: "F";

      case ["y'", "U"]: "U";
      case ["y'", "D"]: "D";
      case ["y'", "F"]: "R";
      case ["y'", "R"]: "B";
      case ["y'", "B"]: "L";
      case ["y'", "L"]: "F";

      case ["z", "F"]: "F";
      case ["z", "B"]: "B";
      case ["z", "U"]: "R";
      case ["z", "R"]: "D";
      case ["z", "D"]: "L";
      case ["z", "L"]: "U";

      case ["z'", "F"]: "F";
      case ["z'", "B"]: "B";
      case ["z'", "U"]: "L";
      case ["z'", "L"]: "D";
      case ["z'", "D"]: "R";
      case ["z'", "R"]: "U";

      case [_,_]: "FAIL";
    }


  public static function main() {
    final rotations:List<String> = CodingGame.readline().split(" ").toList();
    Sys.println(rotations.foldLeft(CodingGame.readline(), rot));
    Sys.println(rotations.foldLeft(CodingGame.readline(), rot));
  }
}