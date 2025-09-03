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
          (SrcPos(_, Lam(x, t)), ns) | (Lam(x, t), ns) => {
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
        guard ns.nth(ix.to_int()) is Some(name) else { logger.write_object(ix) }
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
      Meta(meta) => {
        let me = lookupMeta(meta)
        match me {
          Solved(val) => logger.write_object(val)
          Unsolved => logger.write_string("?\{meta.to_int()}")
        }
      }
      InsertedMeta(meta, bds) => {
        let me = lookupMeta(meta)
        match me {
          Solved(val) => logger.write_object(val)
          Unsolved => logger.write_string("?\{meta.to_int()} \{bds}")
        }
      }
      SrcPos(_, t) => logger.write_object(t)
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
          RSrcPos(_, t) => continue t
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
      RHole => logger.write_string("_")
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

///|
impl Show for Ctx with output(self, logger) {
  let { env, lvl, types, bds, pos } = self
  logger.write_string(
    (
      $| SourcePosition: \{pos.row}:\{pos.col}
      $| env: \{env.rev().iter()}
      $| types: \{types.rev().iter()}
      $| lvl: \{lvl} 
      $| bds: \{bds.rev().iter()}
    ),
  )
}

///|
impl Show for ElabError with output(self, logger) {
  match self {
    NameNotInScope(x, ns) =>
      logger.write_string(
        (
          $| \{x} not in scope 
          $| context: \{ns.rev().iter()}
        ),
      )
    CantUnify(t, u) =>
      logger.write_string(
        (
          $|Can't unify \{t} and \{u}
        ),
      )
  }
}

///|
impl Show for Error_ with output(self, logger) {
  let Error_(ctx, ee) = self
  logger.write_string(
    (
      $|
      $| \{ctx}
      $|
      $| message: \{ee}
      $|
    ),
  )
}
