///
/// simple id function
///
func identity<A>(a: A) -> A {
    return a
}

///
/// Const function
///
func const<A, B>(c: A) -> B -> A {
    return { _ in return c }
}

///
/// Const-unit function, equivalent to ``const(())``
///
func constUnit<B>() -> B -> Void {
    return { _ in }
}