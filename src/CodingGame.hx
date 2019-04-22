#if (js && CodingGame)
@:native("") extern class CodingGameNative {
  public static function readline(): String;
}
#else
final class CodingGameNative {
  inline public static function readline(): String
    return Sys.stdin().readLine();
}
#end

final class CodingGame {
  inline public static function readline(): String
    return CodingGameNative.readline();

  inline public static function readInt(): Int
    return Std.parseInt(readline());
}