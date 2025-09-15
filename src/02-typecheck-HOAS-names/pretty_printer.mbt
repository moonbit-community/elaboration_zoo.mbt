///|
impl Show for Tm with output(self, logger) {
  fn dfs(root : Tm, ns : List[Name]) {
    match root {
      Pi("_", a, b) => {
        logger.write_string("(")
        dfs(a, ns)
        logger.write_string(")")
        logger.write_string(" -> ")
        dfs(b, @list.cons("_", ns))
      }
      Pi(x, a, b) => {
        logger.write_string("(")
        logger.write_string(x)
        logger.write_string(" : ")
        dfs(a, ns)
        logger.write_string(")")
        logger.write_string(" -> ")
        dfs(b, @list.cons(x, ns))
      }
      U => logger.write_string("U")
      App(t, u) => {
        logger.write_char('(')
        dfs(t, ns)
        logger.write_char(' ')
        dfs(u, ns)
        logger.write_char(')')
      }
      Lam(x, t) => {
        logger.write_string("fun ")
        logger.write_string(x)
        let (t, ns) = loop (t, @list.cons(x, ns)) {
          (Lam(x, t), ns) => {
            logger.write_string(" ")
            logger.write_string(x)
            continue (t, @list.cons(x, ns))
          }
          end => end
        }
        logger.write_string(" -> ")
        dfs(t, ns)
      }
      Var(name) => logger.write_string(name)
      Let(x, a, t, u) => {
        logger.write_string("let ")
        logger.write_string(x)
        logger.write_string(" : ")
        dfs(a, ns)
        logger.write_string(" = ")
        dfs(t, ns)
        logger.write_string(";\n")
        dfs(u, @list.cons(x, ns))
      }
      SrcPos(_, t) => logger.write_object(t)
    }
  }

  dfs(self, @list.empty())
}

///|
fn show_val(val : Val, env : Env) -> String {
  quote(val, env).to_string()
}

///|
impl Show for Val with output(self, logger) {
  logger.write_string(show_val(self, Default::default()))
}
