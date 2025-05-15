///|
typealias String as Name

///|
typealias @list.T as List

///|
fnalias @list.(construct as cons, empty as nil)

///|
typealias Tm as Ty

///|
enum Raw {
  /// x
  RVar(Name)
  /// fun x -> t
  RLam(Name, Raw)
  /// t u
  RApp(Raw, Raw)
  /// U 
  RU
  /// (x : A) -> B 
  RPi(Name, Raw, Raw)
  /// let x : A = t; u
  RLet(Name, Raw, Raw, Raw)
  RSrcPos(SourcePos, Raw)
}

///|
enum Tm {
  Var(Ix)
  Lam(Name, Tm)
  App(Tm, Tm)
  U
  Pi(Name, Ty, Ty)
  Let(Name, Ty, Tm, Tm)
}

///|
typealias List[Val] as Env

///|
enum Closure {
  Closure(Env, Tm)
}

///|
typealias Val as VTy

///|
enum Val {
  VVar(Lvl)
  VApp(Val, Val)
  VLam(Name, Closure)
  VPi(Name, VTy, Closure)
  VU
}

///|
typealias List[(Name, VTy)] as Types

///|
struct Ctx {
  env : Env
  types : Types
  lvl : Lvl
  pos : SourcePos
}

///|
suberror TypeError {
  TypeError(SourcePos, String)
} derive(Show)

///|
impl Default for Ctx with default() {
  Ctx::{ env: nil(), types: nil(), lvl: 0, pos: SourcePos::{ row: 0, col: 0 } }
}
