///|
test "unify error" {
  reset()
  let ctx = Default::default()
  let ex = parser.parse(
    #| let foo : U -> U ->  U = 
    #|   fun x -> x;
    #| U
    ,
  )
  inspect(
    ex,
    content=
      #|let foo : (U) -> (U) -> U = fun x -> x;
      #|U
    ,
  )
  inspect(
    try? infer(ex, ctx~),
    content=
      #|Err(
      #|  SourcePosition: 1:11
      #| env: [Ix(-1)]
      #| types: [("x", U)]
      #| lvl: Lvl(1) 
      #| bds: [Bound]
      #|
      #| message: Can't unify (U) -> U and U
      #|)
    ,
  )
}

///|
test "error report" {
  let ctx = Default::default()
  let ex = parser.parse(
    #| let id : (A : U) -> A -> A = fun A x -> x;
    #| let foo : U -> U = U; 
    #| foo
    ,
  )
  inspect(
    try? infer(ex, ctx~),
    content=
      #|Err(
      #|  SourcePosition: 1:19
      #| env: [fun A x -> x]
      #| types: [("id", (A : U) -> (A) -> A)]
      #| lvl: Lvl(1) 
      #| bds: [Defined]
      #|
      #| message: Can't unify (U) -> U and U
      #|)
    ,
  )
}
