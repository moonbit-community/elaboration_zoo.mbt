///|
fn fresh(ns : @list.List[Name], x : Name) -> Name {
  loop x {
    "_" => "_"
    _ as x if ns.contains(x) => continue x + "'"
    _ as x => x
  }
}

///|
fn vApp(t : Val, u : Val) -> Val {
  match t {
    VLam(_, t) => t(u)
    _ => VApp(t, u)
  }
}

///|
fn eval(tm : Tm, env : Env) -> Val {
  match tm {
    App(t, u) => vApp(eval(t, env), eval(u, env))
    Lam(x, t) => VLam(x, u => eval(t, env.prepend((x, u))))
    Var(x) => env.lookup(x).unwrap()
    Let(x, t, u) => eval(u, env.prepend((x, eval(t, env))))
    SrcPos(_, e) => eval(e, env)
  }
}

///|
fn quote(v : Val, ns : List[Name]) -> Tm {
  match v {
    VApp(t, u) => App(quote(t, ns), quote(u, ns))
    VVar(x) => Var(x)
    VLam(x, t) => {
      // eta expansion
      let x = fresh(ns, x)
      let t = quote(t(VVar(x)), List::cons(x, ns))
      Lam(x, t)
    }
  }
}

///|
fn nf(tm : Tm, env : Env) -> Tm {
  let v = eval(tm, env)
  let ns = env.map(x => x.0)
  quote(v, ns)
}

///|
test "ex2" {
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
  inspect(zero, content="(fun f -> (fun x -> x))")
  inspect(nf(zero, nil), content="(fun f -> (fun x -> x))")
  inspect(one, content="(fun f -> (fun x -> (f x)))")
  inspect(nf(one, nil), content="(fun f -> (fun x -> (f x)))")
  inspect(succ, content="(fun n -> (fun f -> (fun x -> (f ((n f) x)))))")
  let one = nf(App(succ, zero), nil)
  inspect(one, content="(fun f -> (fun x -> (f x)))")
  let ten = nf(App(App(add, five), five), nil)
  inspect(
    ten,
    content="(fun f -> (fun x -> (f (f (f (f (f (f (f (f (f (f x))))))))))))",
  )
  let num_25 = nf(App(App(mult, five), five), nil)
  inspect(
    num_25,
    content="(fun f -> (fun x -> (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f x)))))))))))))))))))))))))))",
  )
}
