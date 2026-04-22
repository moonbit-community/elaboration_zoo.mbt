///|
fn[A] cons(x : A, xs : List[A]) -> List[A] {
  @list.cons(x, xs)
}

///|
enum Tm {
  Var(Ix)
  Lam(Tm)
  App(Tm, Tm)
  Let(Tm, Tm)
  SrcPos(SourcePos, Tm)
}

///|
type List[A] = @list.List[A]

///|
type Env = List[Val]

///|
enum Closure {
  Closure(Env, Tm)
}

///|
enum Val {
  VVar(Lvl)
  VApp(Val, Val)
  VLam(Closure)
}
