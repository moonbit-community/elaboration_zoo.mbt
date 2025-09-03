///|
typealias @parserc.(Input, ParseError, Parser, SourcePos)

///|
let space = @parserc.space

///|
let space1 = @parserc.space1

///|
let digit = @parserc.digit

///|
let alphabetic = @parserc.alphabetic

///|
let spaces = @parserc.spaces

///|
fnalias @parserc.(
  between,
  bind,
  char,
  discard_left,
  discard_right,
  eof,
  label,
  map,
  none_of,
  one_of,
  round_bracket,
  square_bracket,
  curly_bracket,
  pure,
  run,
  satisfy,
  string,
  foldl,
  foldr,
  foldl1,
  foldr1,
  discard_spaces,
  many,
  many_each,
  map_srcpos,
  or
)

///|
fnalias Input::new as input

///|
fn symbol(x : String) -> Parser[String] {
  string(x).discard_spaces()
}

///|
let reserved_words : Set[String] = Set::of(["let", "fun"])

///|
let parser : Parser[Tm] = {
  let buffer = StringBuilder::new(size_hint=40)
  let name = (digit | alphabetic)
    .many_each(fn(x) { buffer.write_char(x) })
    .map(fn(_) {
      let res = buffer.to_string()
      buffer.reset()
      res
    })
    .label("name")
  let name : Parser[String] = fn(input) {
    let { row, col, .. } = input
    let (x, rest) = name(input)
    guard not(reserved_words.contains(x)) else {
      raise ParseError::expect(row~, col~, "valid identifiers")
    }
    (x, rest)
  }
  let var_ = name.map(Var(_))
  letrec lam = fn(input : Input) -> (Tm, Input) raise ParseError {
    let fun = symbol("fun")
    let x = name.discard_spaces()
    let arr = symbol("->")
    let t = discard_spaces(expr)
    let lam = fun.discard_left(
      x.bind(x => discard_left(arr, t).map(t => Lam(x, t))),
    )
    lam(input)
  }
  and let_ = fn(input : Input) -> (Tm, Input) raise ParseError {
    let expr = discard_spaces(expr)
    let let_ = symbol("let").discard_left(
      name
      .discard_spaces()
      .bind(fn(x) {
        symbol("=")
        .discard_left(expr)
        .bind(fn(t) {
          symbol(";").discard_left(expr).map(fn(u) { Let(x, t, u) })
        })
      }),
    )
    let_(input)
  }
  and expr = fn(input : Input) -> (Tm, Input) raise ParseError {
    ((lam : Parser[_]) | let_ | var_ | round_bracket(expr))
    .discard_spaces()
    .foldl1(pure_pos(pos => (t, u) => App(t, u)))
    .label("expr")
    .map_srcpos(SrcPos(_, _))(input)
  }

  (expr : Parser[Tm]).discard_right(spaces).discard_right(eof(' '))
}

///|
fn[A] pure_pos(f : (SourcePos) -> A) -> Parser[A] {
  fn(input) { (f({ row: input.row, col: input.col }), input) }
}

///|
test "parser" {
  inspect(parser.run(input("x")), content="x")
  inspect(parser.run(input("(x)")), content="x")
  inspect(parser.run(input("(x x)")), content="(x x)")
  inspect(parser.run(input("fun x -> x")), content="(fun x -> x)")
}

///|
fn[A] Parser::parse(f : Self[A], s : String) -> A raise ParseError {
  f.run(input(s))
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
