///|
fnalias @list.construct as cons

///|
enum Tm {
  Var(Ix)
  Lam(Tm)
  App(Tm, Tm)
  Let(Tm, Tm)
  SrcPos(SourcePos, Tm)
}

///|
typealias @list.T as List

///|
typealias List[Val] as Env

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
