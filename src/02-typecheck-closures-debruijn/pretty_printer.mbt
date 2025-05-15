///|
impl Show for Tm with output(self, logger) {
  fn dfs(root : Tm, ns : List[Name]) {
    match root {
      Pi("_", a, b) => {
        logger.write_string("(")
        dfs(a, ns)
        logger.write_string(")")
        logger.write_string(" -> ")
        dfs(b, cons("_", ns))
      }
      Pi(x, a, b) => {
        logger.write_string("(")
        logger.write_string(x)
        logger.write_string(" : ")
        dfs(a, ns)
        logger.write_string(")")
        logger.write_string(" -> ")
        dfs(b, cons(x, ns))
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
        let (t, ns) = loop (t, cons(x, ns)) {
          (Lam(x, t), ns) => {
            logger.write_string(" ")
            logger.write_string(x)
            continue (t, cons(x, ns))
          }
          end => end
        }
        logger.write_string(" -> ")
        dfs(t, ns)
      }
      Var(ix) => {
        let name = ns.nth(ix.to_int()).unwrap()
        logger.write_string(name)
      }
      Let(x, a, t, u) => {
        logger.write_string("let ")
        logger.write_string(x)
        logger.write_string(" : ")
        dfs(a, ns)
        logger.write_string(" = ")
        dfs(t, ns)
        logger.write_string(";\n")
        dfs(u, cons(x, ns))
      }
    }
  }

  dfs(self, @list.empty())
}

///|
impl Show for Raw with output(self, logger) {
  fn dfs(root : Raw) {
    match root {
      RPi("_", a, b) => {
        logger.write_string("(")
        dfs(a)
        logger.write_string(")")
        logger.write_string(" -> ")
        dfs(b)
      }
      RPi(x, a, b) => {
        logger.write_string("(")
        logger.write_string(x)
        logger.write_string(" : ")
        dfs(a)
        logger.write_string(")")
        logger.write_string(" -> ")
        dfs(b)
      }
      RU => logger.write_string("U")
      RApp(t, u) => {
        logger.write_char('(')
        dfs(t)
        logger.write_char(' ')
        dfs(u)
        logger.write_char(')')
      }
      RLam(x, t) => {
        logger.write_string("fun ")
        logger.write_string(x)
        let t = loop t {
          RLam(x, t) => {
            logger.write_string(" ")
            logger.write_string(x)
            continue t
          }
          t => t
        }
        logger.write_string(" -> ")
        dfs(t)
      }
      RVar(name) => logger.write_string(name)
      RLet(x, a, t, u) => {
        logger.write_string("let ")
        logger.write_string(x)
        logger.write_string(" : ")
        dfs(a)
        logger.write_string(" = ")
        dfs(t)
        logger.write_string(";\n")
        dfs(u)
      }
      RSrcPos(_, e) => dfs(e)
    }
  }

  dfs(self)
}

///|
fn show_val(val : Val, ctx : Ctx) -> String {
  quote(val, ctx.lvl).to_string()
}

///|
impl Show for Val with output(self, logger) {
  logger.write_string(show_val(self, Default::default()))
}
