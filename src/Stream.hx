import haxe.ds.Option;
import haxe.io.Input;

import Prelude;
import ListF;
import Parser;

using Parser.ParserOps;
using Stream.StreamOps;
using Lazy.LazyOps;

abstract Stream<A>(Lazy<ListF<A,Stream<A>>>) {
  inline public function new(stream: Lazy<ListF<A,Stream<A>>>) {
    this = stream;
  }

  private inline function inner(): Lazy<ListF<A,Stream<A>>>
    return this;

  public inline   function run(): ListF<A,Stream<A>>
    return this.force();

  public static inline function empty<B>(): Stream<B>
    return new Stream<B>(Lazy.pure(Nil));

  public static inline function pure<B>(b: B): Stream<B>
    return new Stream<B>(Lazy.pure(Cons(b, empty())));

  public static inline function cons<B>(head: Lazy<B>, tail: Stream<B>): Stream<B>
    return new Stream<B>(head.map(h -> Cons(h, tail)));

  public static function unfold<B,C>(seed: C, f: C -> ListF<B,C>): Stream<B>
    return new Stream<B>(Lazy.delay(() ->
      ListFOps.map2(f(seed), s -> unfold(s, f))
    ));
  
  public function foldp<B,C>(seed:B, f: (A,B) -> ListF<C,B>): Stream<C>
    return new Stream<C>(this.map(s ->
      switch (s) {
        case Nil:
          Nil;
        case Cons(head, tail):
          ListFOps.map2(f(head, seed), seed2 -> tail.foldp(seed2, f));
      }
    ));
  
  public function append(stream: Stream<A>): Stream<A>
    return new Stream<A>(this.flatMap(s ->
      switch (s) {
        case Nil:
          stream.inner();
        case Cons(head, tail):
          Lazy.pure(Cons(head, tail.append(stream)));
      }
    ));

  public function map<B>(f: A -> B): Stream<B>
    return new Stream<B>(this.map(s ->
      switch (s) {
        case Nil:
          Nil;
        case Cons(head, tail):
          Cons(f(head), tail.map(f));
      }
    ));
  
  public function flatMap<B>(f: A -> Stream<B>): Stream<B>
    return new Stream<B>(this.map(s ->
      switch (s) {
        case Nil:
          Nil;
        case Cons(head, tail):
          f(head).append(tail.flatMap(f)).inner().force();
      }
    ));

  public function filter(p: A -> Bool): Stream<A>
    return new Stream<A>(this.map(s ->
      switch (s) {
        case Nil:
          Nil;
        case Cons(head, tail):
          if (p(head))
            Cons(head, tail.filter(p))
          else
            tail.filter(p).inner().force();
      }
    ));

  public function mapFilter<B>(p: A -> Option<B>): Stream<B>
    return new Stream<B>(this.map(s ->
      switch (s) {
        case Nil:
          Nil;
        case Cons(head, tail):
          switch (p(head)) {
            case Some(v):
              Cons(v, tail.mapFilter(p));
            case None:
              tail.mapFilter(p).inner().force();
          }
      }
    ));
  
  public function take(n: Int): Stream<A>
    if (n <= 0)
      return empty()
    else
      return new Stream<A>(this.map(s ->
        switch (s) {
          case Nil: Nil;
          case Cons(head, tail): Cons(head, tail.take(n-1));
        }
      ));
  
  public function drop(n: Int): Stream<A>
    if (n <= 0)
      return new Stream<A>(this);
    else
      return new Stream<A>(this.map(s ->
        switch (s) {
          case Nil: Nil;
          case Cons(_, tail): tail.drop(n-1).inner().force();
        }
      ));

  public function takeWhile(p: A -> Bool): Stream<A>
    return new Stream<A>(this.map(s ->
      switch (s) {
        case Nil: Nil;
        case Cons(head, tail):
          if (p(head))
            Cons(head, tail.takeWhile(p));
          else
            Nil;
      }
    ));
  
  public function dropWhile(p: A -> Bool): Stream<A>
    return new Stream<A>(this.map(s ->
      switch (s) {
        case Nil: Nil;
        case Cons(head, tail):
          if (p(head))
            tail.dropWhile(p).inner().force();
          else
            Cons(head, tail);
      }
    ));

  public static inline function fromString(str: String): Stream<String> {
    final n = str.length;
    return unfold(0, i ->
      if (i < n)
        Cons(str.charAt(i), i + 1)
      else
        Nil
    );
  }

  public function foldLeft<B>(init: B, f: (B,A) -> B): B
    switch (this.force()) {
      case Nil:
        return init;
      case Cons(head, tail):
        return tail.foldLeft(f(init, head),f);
    }
  
  public function forEach(f: A -> Void): Void
    switch (this.force()) {
      case Nil:
        return;
      case Cons(head, tail):
        f(head);
        return tail.forEach(f);
    }

  public static inline function inputLines(input: Input): Stream<String>
    return unfold(0, b -> Cons(input.readLine(), 0));

  public static inline function inputChars(input: Input): Stream<String>
    return inputLines(input).flatMap(line -> fromString(line + "\n"));
  
  public function zip<B>(s: Stream<B>): Stream<Pair<A,B>> {
    final x =
      this.map((x:ListF<A,Stream<A>>) -> (y:ListF<B,Stream<B>>) -> {_1: x, _2: y})
          .ap(s.inner())
          .map((v: Pair<ListF<A,Stream<A>>, ListF<B,Stream<B>>>) ->
            switch [v._1, v._2] {
              case [Cons(h1, t1), Cons(h2, t2)]:
                Cons(({_1: h1, _2: h2}: Pair<A,B>), t1.zip(t2));
              case [_,_]:
                Nil;
            }
          );
    return new Stream(x);
  }
}

final class StreamOps {
  public static inline function ap<A,X>(_this: Stream<A -> X>, fa: Stream<A>): Stream<X>
    return _this.flatMap(f -> fa.map(f));

  public static inline function normSpace(_this: Stream<String>): Stream<String>
    return Parsers
              .space
              .between(Some(1), None)
              .map(_ -> " ")
              .or(Get)
              .runAsStream(_this.dropWhile(Parsers.isSpace), x -> x);

}