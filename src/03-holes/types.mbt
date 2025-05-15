///|
typealias @list.T as List

///|
fnalias @list.(construct as cons, empty as nil)

///|
enum MetaEntry {
  Solved(Val)
  Unsolved
} derive(Show)

///|
typealias Tm as Ty

///|
typealias String as Name

///|
enum BD {
  Bound
  Defined
} derive(Show)

///|
enum Tm {
  Var(Ix)
  Lam(Name, Tm)
  App(Tm, Tm)
  U
  Pi(Name, Ty, Ty)
  Let(Name, Ty, Tm, Tm)
  Meta(MetaVar)
  InsertedMeta(MetaVar, List[BD])
  SrcPos(SourcePos, Tm)
}

///|
typealias List[Val] as Spine

///|
typealias List[Val] as Env

///|
enum Closure {
  Closure(Env, Tm)
}

///|
typealias Val as Vty

///|
enum Val {
  VFlex(MetaVar, Spine) // VVar
  VRigid(Lvl, Spine) // VMeta
  VLam(Name, Closure)
  VPi(Name, Vty, Closure)
  VU
}

///|
typealias Val as VTy

///|
typealias List[(String, VTy)] as Types

///|
struct Ctx {
  env : Env
  lvl : Lvl
  types : Types
  bds : List[BD]
  pos : SourcePos
}

///|
suberror UnifyError String derive(Show)

///|
suberror ElabError {
  NameNotInScope(Name, List[Name])
  CantUnify(Tm, Tm)
}

///|
suberror Error_ {
  Error_(Ctx, ElabError)
}

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
  /// _
  RHole
  RSrcPos(SourcePos, Raw)
}

///|
impl Default for Ctx with default() {
  Ctx::{
    env: nil(),
    lvl: 0,
    types: nil(),
    bds: nil(),
    pos: SourcePos::{ row: 0, col: 0 },
  }
}
