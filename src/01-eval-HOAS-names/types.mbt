///|
type Name = String

///|
type List[A] = @list.List[A]

///|
fn[A] nil() -> List[A] {
  @list.empty()
}

///|
fn[A] cons(x : A, xs : List[A]) -> List[A] {
  @list.cons(x, xs)
}

///|
enum Tm {
  /// x
  Var(Name)
  /// fun x -> t
  Lam(Name, Tm)
  /// t u
  App(Tm, Tm)
  /// let x = t; u
  Let(Name, Tm, Tm)
  SrcPos(SourcePos, Tm)
}

///|
type Env = @list.List[(Name, Val)]

///|
enum Val {
  VVar(Name)
  VApp(Val, Val)
  VLam(Name, (Val) -> Val)
}
