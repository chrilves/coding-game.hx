typedef Monoid<A> = {
  zero: A,
  combine: (A,A) -> A
}