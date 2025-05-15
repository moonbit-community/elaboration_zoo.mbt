///|
fn fresh(ns : Env, x : Name) -> Name {
  loop x {
    "_" => "_"
    _ as x =>
      match ns.lookup(x) {
        None => x
        Some(_) => continue x + "'"
      }
  }
}

///|
fn eval(tm : Tm, env : Env) -> Val {
  match tm {
    Pi(x, a, b) =>
      VPi(x, eval(a, env), fn(u) {
        let env = cons((x, u), env)
        eval(b, env)
      })
    U => VU
    App(t, u) => {
      let t = eval(t, env)
      let u = eval(u, env)
      match t {
        VLam(_, t) => t(u)
        _ => VApp(t, u)
      }
    }
    Lam(x, t) =>
      VLam(x, fn(u) {
        let env = cons((x, u), env)
        eval(t, env)
      })
    Var(x) => env.lookup(x).unwrap()
    Let(x, _, t, u) => {
      let t = eval(t, env)
      let env = cons((x, t), env)
      eval(u, env)
    }
    SrcPos(_, t) => eval(t, env)
  }
}

///|
fn quote(v : Val, env : Env) -> Tm {
  match v {
    VApp(t, u) => {
      let f = quote(t, env)
      let x = quote(u, env)
      App(f, x)
    }
    VVar(x) => Var(x)
    VLam(x, t) => {
      let x = fresh(env, x)
      let env = cons((x, VVar(x)), env)
      let t = quote(t(VVar(x)), env)
      Lam(x, t)
    }
    VU => U
    VPi(x, a, b) => {
      let x = fresh(env, x)
      let a = quote(a, env)
      let b = {
        let env = cons((x, VVar(x)), env)
        quote(b(VVar(x)), env)
      }
      Pi(x, a, b)
    }
  }
}

///|
fn nf(tm : Tm, env : Env) -> Tm {
  quote(eval(tm, env), env)
}

///|
test {
  let nil : Env = nil()

  // \ f x. f(f(f(f(f x))))
  let five = Lam(
    "f",
    Lam(
      "x",
      App(
        Var("f"),
        App(Var("f"), App(Var("f"), App(Var("f"), App(Var("f"), Var("x"))))),
      ),
    ),
  )

  // \ m n f x. m f (n f x)
  let add = Lam(
    "m",
    Lam(
      "n",
      Lam(
        "f",
        Lam(
          "x",
          App(App(Var("m"), Var("f")), App(App(Var("n"), Var("f")), Var("x"))),
        ),
      ),
    ),
  )

  // \ m n. m (n f)
  let mult = Lam(
    "m",
    Lam("n", Lam("f", App(Var("m"), App(Var("n"), Var("f"))))),
  )

  // \ n f x. f (n f x)
  let succ = Lam(
    "n",
    Lam(
      "f",
      Lam(
        "x",
        {
          let n = App(App(Var("n"), Var("f")), Var("x")) // apply f to x, n times
          App(Var("f"), n) // apply f to x, (n + 1) times
        },
      ),
    ),
  )
  // \f x. x 
  let zero = Lam("f", Lam("x", Var("x"))) // apply f to x, 0 times
  let one = Lam("f", Lam("x", App(Var("f"), Var("x")))) // appl f to x. 1 times
  inspect(zero, content="fun f x -> x")
  inspect(nf(zero, nil), content="fun f x -> x")
  inspect(one, content="fun f x -> (f x)")
  inspect(nf(one, nil), content="fun f x -> (f x)")
  inspect(succ, content="fun n f x -> (f ((n f) x))")
  let one = nf(App(succ, zero), nil)
  inspect(one, content="fun f x -> (f x)")
  let ten = nf(App(App(add, five), five), nil)
  inspect(ten, content="fun f x -> (f (f (f (f (f (f (f (f (f (f x))))))))))")
  let num_25 = nf(App(App(mult, five), five), nil)
  inspect(
    num_25,
    content="fun f x -> (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f x)))))))))))))))))))))))))",
  )
}
