///|
test "combinator" {
  let ctx = Default::default()
  let env = Default::default()
  let tm = parser.parse(
    (
      #| let id : (A : U) -> A -> A = 
      #|    fun A -> fun x -> x;
      #| let const : (A : U) -> (B : U) -> A -> B -> A = 
      #|    fun A -> fun B -> fun x -> fun y -> x;
      #| id ((A : U) -> (B : U) -> A -> B -> A) const 
    ),
  )
  inspect(
    tm,
    content=(
      #|let id : (A : U) -> (A) -> A = fun A x -> x;
      #|let const : (A : U) -> (B : U) -> (A) -> (B) -> A = fun A B x y -> x;
      #|((id (A : U) -> (B : U) -> (A) -> (B) -> A) const)
    ),
  )
  let ty = infer(tm, ctx~, env~)
  inspect(nf(tm, nil()), content="fun A B x y -> x")
  inspect(ty, content="(A : U) -> (B : U) -> (A) -> (B) -> A")
}

///|
test "Nat" {
  let ctx = Default::default()
  let env = Default::default()
  let tm = parser.parse(
    (
      #| let Nat : U = (N : U) -> (N -> N) -> N -> N;
      #| let add : Nat -> Nat -> Nat = fun m -> fun n -> fun N -> fun f -> fun x ->  m N f (n N f x);
      #| let five : Nat = fun N -> fun f -> fun x -> f(f(f(f(f x))));
      #| let ten : Nat= add five five;
      #| ten
    ),
  )
  let ty = infer(tm, ctx~, env~)
  inspect(
    nf(tm, nil()),
    content="fun N f x -> (f (f (f (f (f (f (f (f (f (f x))))))))))",
  )
  inspect(ty, content="(N : U) -> ((N) -> N) -> (N) -> N")
}
