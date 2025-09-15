///|
fn appCl(cl : Closure, u : Val) -> Val {
  let Closure(env, t) = cl
  eval(t, env.prepend(u))
}

///|
fn eval(tm : Tm, env : Env) -> Val {
  match tm {
    App(t, u) =>
      match (eval(t, env), eval(u, env)) {
        (VLam(t), u) => appCl(t, u)
        (t, u) => VApp(t, u)
      }
    Lam(t) => VLam(Closure(env, t))
    Var(x) => env.nth(x.to_int()).unwrap()
    Let(t, u) => eval(u, env.prepend(eval(t, env)))
    SrcPos(_, e) => eval(e, env)
  }
}

///|
fn quote(val : Val, len : Int) -> Tm {
  match val {
    VApp(t, u) => App(quote(t, len), quote(u, len))
    VVar(x) => Var(x.to_ix(len))
    VLam(t) => {
      // eta expansion
      let y = VVar(Lvl(len)) // `VVar(Lvl(len))` == `Var(Ix(0))`
      let t_ = appCl(t, y) //  (fun x -> t) y
      Lam(quote(t_, len + 1)) // fun y -> (fun x -> t) y
    }
  }
}

/// De Bruijn index/De Bruijn level
///
/// De Bruijn index uses `List::nth` to reference values in `env`.
/// De Bruijn level uses `List::rev_nth` to reference values in `env`, actually first converting to `De Bruijn index` using `Lvl::to_ix` then referencing values.
/// 
/// Using De Bruijn index makes it convenient to embed `closed term` into arbitrary expressions, 
/// where `closed term` refers to expressions without any free variables, e.g. `fun x -> x`.
/// 
/// Using De Bruijn level when adding values to `env` with `cons` doesn't require changing values in the term.
/// 
/// e.g: index 
/// Warning: This uses Cons List, not the conventional Snoc List.
/// 
/// When using `De Bruijn index`, after cons-ing to env, you need to +1 to values in the term to not violate the property,
/// this operation is also called `shift`.
/// 
/// Here's a brief introduction to shift
/// 
/// https://github.com/illusory0x0/elaboration_zoo.mbt/blob/master/dbi-shift.md
/// 
/// eval(Var(0),[(y,0)])        [x |-> y](x)
/// 
/// eval(Var(1),[(z,1),(y,0)])  [x |-> y](x)
/// 
/// e.g: level
/// 
/// Here `VVar(0)` always references the element with index 0 counting from right to left, no need to change values in the term, so it's very convenient.
/// 
/// eval(VVar(0),[(y,0)])        [x |-> y](x)
/// 
/// eval(VVar(0),[(z,1),(y,0)])  [x |-> y](x)
/// 
/// 
/// 
/// https://guest0x0.xyz/NBE-intro.pdf
/// https://en.wikipedia.org/wiki/Lambda_calculus#%CE%B7-conversion
/// https://en.wikipedia.org/wiki/De_Bruijn_index

///|
fn nf(tm : Tm, env : Env) -> Tm {
  quote(eval(tm, env), env.length())
}

///|
fn var_(x : Int) -> Tm {
  Var(Ix(x))
}

///|
test {
  let nil = @list.empty()

  // var_(1): f
  // var_(0): x
  // \ f x. f(f(f(f(f x))))
  let five = Lam(
    Lam(
      App(
        var_(1),
        App(var_(1), App(var_(1), App(var_(1), App(var_(1), var_(0))))),
      ),
    ),
  )
  // var_(3): m
  // var_(2): n
  // var_(1): f
  // var_(0): x
  // \ m n f x. m f (n f x)
  let add = Lam(
    Lam(
      Lam(Lam(App(App(var_(3), var_(1)), App(App(var_(2), var_(1)), var_(0))))),
    ),
  )

  // var_(2): m
  // var_(1): n
  // var_(0): f
  // \ m n. m (n f)
  let mult = Lam(Lam(Lam(App(var_(2), App(var_(1), var_(0))))))

  // var_(2): n 
  // var_(1): f
  // var_(0): x
  // \ n f x. f (n f x)
  let succ = Lam(
    Lam(
      Lam(
        {
          let n = App(App(var_(2), var_(1)), var_(0)) // apply f to x, n times
          App(var_(1), n) // apply f to x, (n + 1) times
        },
      ),
    ),
  )
  // var_(1): f
  // var_(0): x
  // \f x. x 
  let zero = Lam(Lam(var_(0))) // apply f to x, 0 times
  let one = Lam(Lam(App(var_(1), var_(0)))) // appl f to x. 1 times
  inspect(zero, content="(λ (λ 0))")
  inspect(nf(zero, nil), content="(λ (λ 0))")
  inspect(one, content="(λ (λ (1 0)))")
  inspect(nf(zero, nil), content="(λ (λ 0))")
  inspect(succ, content="(λ (λ (λ (1 ((2 1) 0)))))")
  let one = nf(App(succ, zero), nil)
  inspect(one, content="(λ (λ (1 0)))")
  let ten = nf(App(App(add, five), five), nil)
  inspect(ten, content="(λ (λ (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 0))))))))))))")
  let num_25 = nf(App(App(mult, five), five), nil)
  inspect(
    num_25,
    content="(λ (λ (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 0)))))))))))))))))))))))))))",
  )
}

///|
test "ex2" {
  let nil : Env = @list.empty()
  let five = parser.parse("(λ (λ (1 (1 (1 (1 (1 0)))))))")
  let add = parser.parse("(λ (λ (λ (λ ((3 1) ((2 1) 0))))))")
  let mul = parser.parse("(λ (λ (λ (2 (1 0)))))")
  let succ = parser.parse("(λ (λ (λ (1 ((2 1) 0)))))")
  let zero = parser.parse("(λ (λ 0))")
  let one = parser.parse("(λ (λ (1 0)))")
  let ex = parser.parse(
    (
      #| let (λ (λ (λ (λ ((3 1) ((2 1) 0))))));
      #| let (λ (λ (1 (1 (1 (1 (1 0)))))));
      #| let 1 0 0;
      #| 0
    ),
  )
  inspect(
    nf(ex, nil),
    content="(λ (λ (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 0))))))))))))",
  )
}
