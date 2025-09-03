///|
test "id" {
  reset()
  let ex = parser.parse(
    (
      #| let id : (A : _) -> A -> A = 
      #|    fun A x -> x; 
      #| id 
    ),
  )
  let (tm, ty) = infer(ex, ctx=emptyCtx)
  inspect(
    tm,
    content=(
      #|let id : (A : U) -> (A) -> A = fun A x -> x;
      #|id
    ),
  )
  inspect(ty, content="(A : U) -> (A) -> A")
}

///|
test "combinator" {
  reset()
  let ctx = Default::default()
  let ex0 = parser.parse(
    (
      #| let id : (A : U) -> A -> A = 
      #|    fun A -> fun x -> x;
      #| let const : (A : U) -> (B : U) -> A -> B -> A = 
      #|    fun A -> fun B -> fun x -> fun y -> x;
      #| id ((A : U) -> (B : U) -> A -> B -> A) const 
    ),
  )
  inspect(
    ex0,
    content=(
      #|let id : (A : U) -> (A) -> A = fun A x -> x;
      #|let const : (A : U) -> (B : U) -> (A) -> (B) -> A = fun A B x y -> x;
      #|((id (A : U) -> (B : U) -> (A) -> (B) -> A) const)
    ),
  )
  let (tm, ty) = infer(ex0, ctx~)
  inspect(nf(tm, nil()), content="fun A B x y -> x")
  inspect(ty, content="(A : U) -> (B : U) -> (A) -> (B) -> A")
}

///|
test "Nat" {
  reset()
  let ctx = Default::default()
  let ex1 = parser.parse(
    (
      #| let Nat : U = (N : U) -> (N -> N) -> N -> N;
      #| let add : Nat -> Nat -> Nat = fun m n N f x ->  m N f (n N f x);
      #| let five : Nat = fun N f x-> f(f(f(f(f x))));
      #| let ten : Nat= add five five;
      #| ten
    ),
  )
  let (tm, ty) = infer(ex1, ctx~)
  inspect(
    tm,
    content=(
      #|let Nat : U = (N : U) -> ((N) -> N) -> (N) -> N;
      #|let add : (Nat) -> (Nat) -> Nat = fun m n N f x -> (((m N) f) (((n N) f) x));
      #|let five : Nat = fun N f x -> (f (f (f (f (f x)))));
      #|let ten : Nat = ((add five) five);
      #|ten
    ),
  )
  inspect(
    nf(tm, nil()),
    content="fun N f x -> (f (f (f (f (f (f (f (f (f (f x))))))))))",
  )
  inspect(mctx, content="{val: @immut/sorted_map.of([])}")
  inspect(ty, content="(N : U) -> ((N) -> N) -> (N) -> N")
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
    "f",
    Lam(
      "x",
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
    "m",
    Lam(
      "n",
      Lam(
        "f",
        Lam(
          "x",
          App(App(var_(3), var_(1)), App(App(var_(2), var_(1)), var_(0))),
        ),
      ),
    ),
  )

  // var_(2): m
  // var_(1): n
  // var_(0): f
  // \ m n. m (n f)
  let mult = Lam("m", Lam("n", Lam("f", App(var_(2), App(var_(1), var_(0))))))

  // var_(2): n 
  // var_(1): f
  // var_(0): x
  // \ n f x. f (n f x)
  let succ = Lam(
    "n",
    Lam(
      "f",
      Lam(
        "x",
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
  let zero = Lam("f", Lam("x", var_(0))) // apply f to x, 0 times
  let one = Lam("f", Lam("x", App(var_(1), var_(0)))) // appl f to x. 1 times
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

///|
test "parser" {
  inspect(parser.run(input("fun x -> x")), content="fun x -> x")
  inspect(parser.run(input("fun x y -> x")), content="fun x y -> x")
  inspect(parser.run(input("x x")), content="(x x)")
  inspect(parser.run(input("x")), content="x")
  inspect(parser.run(input("(x)")), content="x")
  inspect(parser.run(input("U")), content="U")
  inspect(parser.run(input("(A : U) -> U")), content="(A : U) -> U")
  inspect(
    parser.run(input("(A : U) -> (x : A) -> A")),
    content="(A : U) -> (x : A) -> A",
  )
  inspect(parser.run(input("U -> U")), content="(U) -> U")
  inspect(parser.run(input("U -> U -> U")), content="(U) -> (U) -> U")
  inspect(parser.run(input("_")), content="_")
}
