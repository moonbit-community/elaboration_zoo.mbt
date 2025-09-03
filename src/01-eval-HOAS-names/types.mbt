///|
typealias String as Name

///|
typealias @moonbitlang/core/list.List

///|
fnalias @list.(construct as cons, empty as nil)

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
typealias @list.List[(Name, Val)] as Env

///|
enum Val {
  VVar(Name)
  VApp(Val, Val)
  VLam(Name, (Val) -> Val)
}
