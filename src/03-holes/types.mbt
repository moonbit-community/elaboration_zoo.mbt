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
enum MetaEntry {
  Solved(Val)
  Unsolved
} derive(Show)

///|
type Ty = Tm

///|
type Name = String

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
type Spine = @list.List[Val]

///|
type Env = @list.List[Val]

///|
enum Closure {
  Closure(Env, Tm)
}

///|
type Vty = Val

///|
enum Val {
  VFlex(MetaVar, Spine) // VVar
  VRigid(Lvl, Spine) // VMeta
  VLam(Name, Closure)
  VPi(Name, Vty, Closure)
  VU
}

///|
type VTy = Val

///|
type Types = @list.List[(String, VTy)]

///|
struct Ctx {
  env : Env
  lvl : Lvl
  types : Types
  bds : @list.List[BD]
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
