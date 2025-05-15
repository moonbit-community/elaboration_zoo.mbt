///|
fn eval(tm : Tm, env : Env) -> Val {
  match tm {
    Meta(m) => vMeta(m)
    Let(_, _, t, u) => eval(u, cons(eval(t, env), env))
    Pi(x, a, b) => VPi(x, eval(a, env), Closure(env, b))
    U => VU
    App(t, u) => vApp(eval(t, env), eval(u, env))
    Lam(x, t) => VLam(x, Closure(env, t))
    Var(x) => env.unsafe_nth(x.to_int())
    InsertedMeta(m, bds) => vAppBDs(vMeta(m), env~, bds~)
    SrcPos(_, t) => eval(t, env)
  }
}

///|
fn quote(t : Val, len : Lvl) -> Tm {
  match force(t) {
    VPi(x, a, b) => Pi(x, quote(a, len), quote(appCl(b, vVar(len)), len + 1))
    VLam(x, t) => Lam(x, quote(appCl(t, vVar(len)), len + 1))
    VRigid(x, sp) => quoteSp(len, Var(x.to_ix(len)), sp)
    VFlex(m, sp) => quoteSp(len, Meta(m), sp)
    VU => U
  }
}

///|
fn nf(tm : Tm, env : Env) -> Tm {
  quote(eval(tm, env), Lvl(env.length()))
}

///|
fn appCl(cl : Closure, u : Val) -> Val {
  let Closure(env, t) = cl
  eval(t, cons(u, env))
}

///|
fn vApp(val : Val, u : Val) -> Val {
  match val {
    VLam(_, t) => appCl(t, u)
    VFlex(m, sp) => VFlex(m, cons(u, sp))
    VRigid(x, sp) => VRigid(x, cons(u, sp))
    _ => abort("impossible")
  }
}

///|
fn vAppSp(val : Val, sp : Spine) -> Val {
  sp.to_array().rev_fold(init=val, vApp)
}

///|
fn vAppBDs(v : Val, env~ : Env, bds~ : List[BD]) -> Val {
  match (env, bds) {
    (Empty, Empty) => v
    (More(t, tail=env), More(Bound, tail=bds)) =>
      vApp(vAppBDs(v, env~, bds~), t)
    (More(t, tail=env), More(Defined, tail=bds)) => vAppBDs(v, env~, bds~)
    _ => abort("impossible")
  }
}
