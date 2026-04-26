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
type Ty = Tm

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
type Env = @list.List[Val]

///|
enum Closure {
  Closure(Env, Tm)
}

///|
type VTy = Val

///|
enum Val {
  VVar(Lvl)
  VApp(Val, Val)
  VLam(Name, Closure)
  VPi(Name, VTy, Closure)
  VU
}

///|
type Types = List[(Name, VTy)]

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
}

///|
pub impl Show for TypeError with output(self, logger) {
  let TypeError(pos, msg) = self
  logger.write_string("TypeError(")
  logger.write_object(pos)
  logger.write_string(", ")
  logger.write_object(msg)
  logger.write_char(')')
}

///|
impl Default for Ctx with default() {
  Ctx::{ env: nil(), types: nil(), lvl: 0, pos: SourcePos::{ row: 0, col: 0 } }
}
