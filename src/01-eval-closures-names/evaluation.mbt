///|
fn fresh(ns : List[Name], x : Name) -> Name {
  loop x {
    "_" => "_"
    _ as x if ns.contains(x) => continue x + "'"
    _ as x => x
  }
}

///|
fn freshCl(cl : Closure, ns : List[Name]) -> Name {
  let Closure(x, _, _) = cl
  fresh(ns, x)
}

///|
/// 调用 `appCl` 是真正发生 subsitituion 的地方
fn appCl(cl : Closure, u : Val) -> Val {
  let Closure(x, env, t) = cl
  eval(t, cons((x, u), env))
}

///|
fn eval(tm : Tm, env : Env) -> Val {
  match tm {
    App(t, u) =>
      match (eval(t, env), eval(u, env)) {
        (VLam(t), u) => appCl(t, u)
        (t, u) => VApp(t, u)
      }
    Lam(x, t) => VLam(Closure(x, env, t))
    Var(x) => env.lookup(x).unwrap()
    Let(x, t, u) => eval(u, cons((x, eval(t, env)), env))
    SrcPos(_, e) => eval(e, env)
  }
}

///|
fn quote(v : Val, ns : @list.List[Name]) -> Tm {
  match v {
    VApp(t, u) => App(quote(t, ns), quote(u, ns))
    VVar(x) => Var(x)
    VLam(cl) => {
      // eta expansion
      let x = freshCl(cl, ns) // 这里需要 `fresh renaming`, 避免把原本是自由变量(free variable)当成是束缚变量(bound variable)
      // 使用 DBI 需要 `shift` 维护 DBI的性质， 这里需要 `fresh renaming`, 处理 CAS 都是很麻烦的事情
      // https://en.wikipedia.org/wiki/Lambda_calculus#Free_variables
      // https://en.wikipedia.org/wiki/Lambda_calculus#Capture-avoiding_substitutions
      let t = quote(appCl(cl, VVar(x)), cons(x, ns))
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
test "ex1" {
  let nil : Env = nil()
  let five = parser.parse("fun f -> fun x -> f(f(f(f(f x))))")
  let add = parser.parse(
    (
      #| fun m -> 
      #|   fun n -> 
      #|     fun f -> 
      #|       fun x -> 
      #|         m f (n f x)
    ),
  )
  let mul = parser.parse("fun m -> fun n -> m (n f)")
  let succ = parser.parse("fun n -> fun f -> fun x -> f (n f x)")
  let zero = parser.parse("fun f -> fun x -> x")
  let one = parser.parse("fun f -> fun x -> f x")
  let ex = parser.parse(
    (
      #| let add = fun m -> 
      #|             fun n -> 
      #|               fun f -> 
      #|                 fun x -> 
      #|                   m f (n f x);
      #| let five = fun f -> fun x -> f(f(f(f(f x))));
      #| let ten = add five five;
      #| ten
    ),
  )
  inspect(
    nf(ex, nil),
    content="(fun f -> (fun x -> (f (f (f (f (f (f (f (f (f (f x))))))))))))",
  )
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
