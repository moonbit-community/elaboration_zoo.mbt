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
}

///|
pub impl Show for MetaEntry with output(self, logger) {
  match self {
    Solved(v) => {
      logger.write_string("Solved(")
      logger.write_object(v)
      logger.write_char(')')
    }
    Unsolved => logger.write_string("Unsolved")
  }
}

///|
type Ty = Tm

///|
type Name = String

///|
enum BD {
  Bound
  Defined
}

///|
pub impl Show for BD with output(self, logger) {
  match self {
    Bound => logger.write_string("Bound")
    Defined => logger.write_string("Defined")
  }
}

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
suberror UnifyError {
  UnifyError(String)
}

///|
pub impl Show for UnifyError with output(self, logger) {
  let UnifyError(msg) = self
  logger.write_string("UnifyError(")
  logger.write_object(msg)
  logger.write_char(')')
}

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
