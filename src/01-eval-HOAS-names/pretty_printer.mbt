///|
impl Show for Tm with output(self, logger) {
  match self {
    App(t, u) => {
      logger.write_char('(')
      logger.write_object(t)
      logger.write_char(' ')
      logger.write_object(u)
      logger.write_char(')')
    }
    Lam(x, t) => {
      logger.write_string("(fun ")
      logger.write_string(x)
      logger.write_string(" -> ")
      logger.write_object(t)
      logger.write_char(')')
    }
    Var(name) => logger.write_string(name)
    Let(x, t, u) => {
      logger.write_string("let ")
      logger.write_string(x)
      logger.write_string(" = ")
      logger.write_object(t)
      logger.write_string(";\n")
      logger.write_object(u)
    }
    SrcPos(_, e) => logger.write_object(e)
  }
}
