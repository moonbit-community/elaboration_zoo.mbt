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
let reserved_words : Set[String] = Set::of(["let", "fun", "U"])

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
    .discard_spaces()
    .label("name")
  let univ = symbol("U").discard_left(pure(U))
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
    let parser = symbol("fun")
      .discard_left(
        foldr(
          name,
          discard_left(symbol("->"), expr),
          pure(fn(t, x) { Lam(x, t) }),
        ),
      )
      .label("lambda")
    parser(input)
  }
  and let_ = fn(input : Input) -> (Tm, Input) raise ParseError {
    let parser = symbol("let")
      .discard_left(
        name.bind(fn(x) {
          symbol(":")
          .discard_left(expr)
          .bind(fn(a) {
            symbol("=")
            .discard_left(expr)
            .bind(fn(t) {
              symbol(";").discard_left(expr).map(fn(u) { Let(x, a, t, u) })
            })
          })
        }),
      )
      .label("let")
    parser(input)
  }
  and pi = fn(input : Input) -> (Raw, Input) raise ParseError {
    discard_left(symbol("("), name)
    .discard_right(symbol(":"))
    .bind(fn(x) {
      discard_right(expr, symbol(")")).bind(fn(a) {
        discard_left(symbol("->"), expr).map(fn(b) { Pi(x, a, b) })
      })
    })
    .label("pi type")(input)
  }
  and expr = fn(input : Input) -> (Tm, Input) raise ParseError {
    let apply = pure_pos(fn(pos) { fn(t, u) { SrcPos(pos, App(t, u)) } }).label(
      "function application",
    )
    let arrow = symbol("->")
      .discard_left(
        pure_pos(fn(pos) { fn(acc, x) { SrcPos(pos, Pi("_", x, acc)) } }),
      )
      .label("arrow type")
    let nlr : Parser[Tm] = (univ | lam | let_ | pi | var_ | round_bracket(expr)).discard_spaces()
    let parser = nlr.foldl1(apply).foldr1(arrow)
    parser(input)
  }

  (expr : Parser[Raw])
  .map_srcpos(SrcPos(_, _))
  .discard_right(spaces)
  .discard_right(eof(' '))
}

///|
fn symbol(x : String) -> Parser[String] {
  string(x).discard_spaces()
}

///|
fn[A] Parser::parse(f : Self[A], s : String) -> A raise ParseError {
  f.run(input(s))
}

///|
fn[A] pure_pos(f : (SourcePos) -> A) -> Parser[A] {
  fn(input) { (f({ row: input.row, col: input.col }), input) }
}
