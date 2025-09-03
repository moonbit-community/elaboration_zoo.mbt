///|
test "elab id" {
  reset()
  let ex = parser.parse(
    (
      #| let id : (A : _) -> A -> A = 
      #|    fun A x -> x; 
      #| id _ U
    ),
  )
  let (tm, ty) = infer(ex, ctx=emptyCtx)
  inspect(
    tm,
    content=(
      #|let id : (A : U) -> (A) -> A = fun A x -> x;
      #|((id U) U)
    ),
  )
  inspect(ty, content="U")
}

///|
test "elab List" {
  reset()
  let ctx = Default::default()
  let ex = parser.parse(
    (
      #| let List : U -> U =
      #|   fun A -> (L : _) -> (A -> L -> L) -> L -> L;
      #|
      #| let nil : (A : _) -> List A = 
      #|   fun A L cons nil -> nil;
      #| 
      #| let cons : (A : _) -> A -> List A -> List A = 
      #|   fun A x xs L cons nil -> cons x (xs _ cons nil);
      #|
      #| let Bool : U = 
      #|   (B : _) -> B -> B -> B;
      #|
      #| let true : Bool = 
      #|   fun B t f -> t; 
      #|
      #| let false : Bool =
      #|   fun B t f -> f; 
      #| 
      #| let id : (A : U) -> A -> A = fun A x -> x;
      #|
      #| let lst : List Bool = 
      #|   cons _ (id _ true) (nil _);
      #| lst 
    ),
  )
  inspect(
    ex,
    content=(
      #|let List : (U) -> U = fun A -> (L : _) -> ((A) -> (L) -> L) -> (L) -> L;
      #|let nil : (A : _) -> (List A) = fun A L cons nil -> nil;
      #|let cons : (A : _) -> (A) -> ((List A)) -> (List A) = fun A x xs L cons nil -> ((cons x) (((xs _) cons) nil));
      #|let Bool : U = (B : _) -> (B) -> (B) -> B;
      #|let true : Bool = fun B t f -> t;
      #|let false : Bool = fun B t f -> f;
      #|let id : (A : U) -> (A) -> A = fun A x -> x;
      #|let lst : (List Bool) = (((cons _) ((id _) true)) (nil _));
      #|lst
    ),
  )
  let (tm, ty) = infer(ex, ctx~)
  inspect(
    nf(tm, nil()),
    content="fun L cons nil -> ((cons fun B t f -> t) nil)",
  )
  inspect(
    ty,
    content="(L : U) -> (((B : U) -> (B) -> (B) -> B) -> (L) -> L) -> (L) -> L",
  )
}

///|
test "elab combinator" {
  reset()
  let ctx = Default::default()
  let ex = parser.parse(
    (
      #| let id : (A : U) -> A -> A = 
      #|    fun A -> fun x -> x;
      #| let const : (A : U) -> (B : U) -> A -> B -> A = 
      #|    fun A -> fun B -> fun x -> fun y -> x;
      #| id _ const 
    ),
  )
  inspect(
    ex,
    content=(
      #|let id : (A : U) -> (A) -> A = fun A x -> x;
      #|let const : (A : U) -> (B : U) -> (A) -> (B) -> A = fun A B x y -> x;
      #|((id _) const)
    ),
  )
  let (tm, ty) = infer(ex, ctx~)
  inspect(nf(tm, nil()), content="fun A B x y -> x")
  inspect(ty, content="(A : U) -> (B : U) -> (A) -> (B) -> A")
}
