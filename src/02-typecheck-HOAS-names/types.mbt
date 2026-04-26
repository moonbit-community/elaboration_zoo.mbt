///|
type Name = String

///|
type Ty = Tm

///|
type Raw = Tm

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
type Closure = (Val) -> Val

///|
enum Val {
  VVar(Name)
  VApp(Val, Val)
  VLam(Name, Closure)
  VPi(Name, Val, Closure)
  VU
}

///|
type List[A] = @list.List[A]

///|
type Env = @list.List[(Name, Val)]

///|
type VTy = Val

///|
type Ctx = @list.List[(Name, VTy)]

///|
fn[A] nil() -> List[A] {
  @list.empty()
}

///|
fn[A] cons(x : A, xs : List[A]) -> List[A] {
  @list.cons(x, xs)
}
