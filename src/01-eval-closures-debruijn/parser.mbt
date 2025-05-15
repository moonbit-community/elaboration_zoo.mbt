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
let parser : Parser[Tm] = {
  let buffer = StringBuilder::new(size_hint=40)
  let index = digit
    .many_each(fn(x) { buffer.write_char(x) })
    .map(fn(_) {
      let res = buffer.to_string()
      buffer.reset()
      res
    })
    .label("debruijn")
  let index : Parser[Ix] = fn(input) {
    let { row, col, .. } = input
    let (x, rest) = index(input)
    let ix = try @strconv.parse_int(x) |> Ix catch {
      _ => raise ParseError::expect(row~, col~, "valid debruijn index")
    }
    (ix, rest)
  }
  let var_ = index.map(Var(_))
  letrec lam = fn(input : Input) -> (Tm, Input) raise ParseError {
    let fun = symbol("\\") | symbol("λ")
    let t = discard_spaces(expr)
    let lam = fun.discard_left(t.map(t => Lam(t)))
    lam(input)
  }
  and let_ = fn(input : Input) -> (Tm, Input) raise ParseError {
    let expr = discard_spaces(expr)
    let let_ = symbol("let").discard_left(
      discard_spaces(expr).bind(fn(t) {
        symbol(";").discard_left(expr).map(fn(u) { Let(t, u) })
      }),
    )
    let_(input)
  }
  and expr = fn(input : Input) -> (Tm, Input) raise ParseError {
    ((lam : Parser[_]) | let_ | var_ | round_bracket(expr))
    .discard_spaces()
    .foldl1(pure_pos(pos => (t, u) => SrcPos(pos, App(t, u))))
    .label("expr")
    .map_srcpos(SrcPos(_, _))(input)
  }

  (expr : Parser[Tm]).discard_right(spaces).discard_right(eof(' '))
}

///|
fn symbol(x : String) -> Parser[String] {
  string(x).discard_spaces()
}

///|
fn[A] pure_pos(f : (SourcePos) -> A) -> Parser[A] {
  fn(input) { (f({ row: input.row, col: input.col }), input) }
}

///|
fn[A] Parser::parse(f : Self[A], s : String) -> A raise ParseError {
  f.run(input(s))
}

///|
test "parser" {
  inspect(parser.run(input("0")), content="0")
  inspect(parser.run(input("(0)")), content="0")
  inspect(parser.run(input("(0 0)")), content="(0 0)")
  inspect(parser.run(input("(0 0)")), content="(0 0)")
  inspect(parser.run(input("\\ 0")), content="(λ 0)")
  inspect(
    parser.run(
      input(
        #| let \0;
        #| 0
        #|
        ,
      ),
    ),
    content=
      #|let (λ 0);
      #|0
    ,
  )
}
