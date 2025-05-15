///|
fn appCl(cl : Closure, u : Val) -> Val {
  let Closure(env, t) = cl
  eval(t, cons(u, env))
}

///|
fn eval(tm : Tm, env : Env) -> Val {
  match tm {
    App(t, u) =>
      match (eval(t, env), eval(u, env)) {
        (VLam(_, t), u) => appCl(t, u)
        (t, u) => VApp(t, u)
      }
    Lam(x, t) => VLam(x, Closure(env, t))
    Var(x) => env.nth(x.to_int()).unwrap()
    Let(_, _, t, u) => {
      let x = eval(t, env)
      let env = cons(x, env)
      eval(u, env)
    }
    U => VU
    Pi(x, a, b) => VPi(x, eval(a, env), Closure(env, b))
  }
}

///|
fn quote(val : Val, len : Lvl) -> Tm {
  match val {
    VApp(t, u) => {
      let f = quote(t, len)
      let x = quote(u, len)
      App(f, x)
    }
    VVar(x) => Var(x.to_ix(len))
    VLam(x, t) => Lam(x, quote(appCl(t, VVar(len)), len + 1))
    VU => U
    VPi(x, a, b) => Pi(x, quote(a, len), quote(appCl(b, VVar(len)), len + 1))
  }
}

///|
fn nf(tm : Tm, env : Env) -> Tm {
  quote(eval(tm, env), Lvl(env.length()))
}
