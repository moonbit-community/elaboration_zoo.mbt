///|
typealias String as Name

///|
typealias Tm as Ty

///|
typealias Tm as Raw

///|
enum Tm {
  Var(Name)
  Lam(Name, Tm)
  App(Tm, Tm)
  U
  Pi(Name, Ty, Ty)
  Let(Name, Ty, Tm, Tm)
  SrcPos(SourcePos, Tm)
}

///|
typealias (Val) -> Val as Closure

///|
enum Val {
  VVar(Name)
  VApp(Val, Val)
  VLam(Name, Closure)
  VPi(Name, Val, Closure)
  VU
}

///|
typealias @list.T as List

///|
typealias List[(Name, Val)] as Env

///|
typealias Val as VTy

///|
typealias List[(Name, VTy)] as Ctx

///|
fnalias @list.(construct as cons, empty as nil)
