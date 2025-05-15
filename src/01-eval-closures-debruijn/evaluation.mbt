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
        (VLam(t), u) => appCl(t, u)
        (t, u) => VApp(t, u)
      }
    Lam(t) => VLam(Closure(env, t))
    Var(x) => env.nth(x.to_int()).unwrap()
    Let(t, u) => eval(u, cons(eval(t, env), env))
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
/// De Bruijn index 用 `List::nth` 来引用在 `env` 里面的值。
/// De Bruijn level 用 `List::rev_nth` 来引用 `env` 里面的值， 这里实际先用 `Lvl::to_ix` 先转换成 `De Bruijn index` 再引用值。
/// 
/// 使用 De Bruijn index 可以很方便的把 `closed term` 嵌入任意表达式， 
/// 这里 `closed term` 是指没有任何自由变量的表达式， e.g. `fun x -> x`。
/// 
/// 使用 De Bruijn level 在使用 `cons` 往 `env` 添加值的时候，不需要改变 term 里面的值。
/// 
/// e.g: index 
/// Warning: 这里用的是 Cons List, 而不是惯例的 Snoc List。
/// 
/// 这里使用 `De Bruijn index`, 对 env 进行 cons 后， 需要对 term 里面的值 +1, 才不会违反性质，
/// 这个操作也称为 `shift`。
/// 
/// eval(Var(0),[(y,0)])        [x |-> y](x)
/// 
/// eval(Var(1),[(z,1),(y,0)])  [x |-> y](x)
/// 
/// e.g: level
/// 
/// 这里 `VVar(0)` 永远引用， 从右边往左数的，索引为0的元素，不需要改变 term 里面的值，所以非常方便。
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
    #| let (λ (λ (λ (λ ((3 1) ((2 1) 0))))));
    #| let (λ (λ (1 (1 (1 (1 (1 0)))))));
    #| let 1 0 0;
    #| 0
    ,
  )
  inspect(
    nf(ex, nil),
    content="(λ (λ (1 (1 (1 (1 (1 (1 (1 (1 (1 (1 0))))))))))))",
  )
}
