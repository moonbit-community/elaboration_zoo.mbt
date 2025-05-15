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
    Lam(t) => {
      logger.write_string("(\u03bb ")
      logger.write_object(t)
      logger.write_char(')')
    }
    Var(ix) => logger.write_object(ix.to_int())
    Let(t, u) => {
      logger.write_string("let ")
      logger.write_object(t)
      logger.write_string(";\n")
      logger.write_object(u)
    }
    SrcPos(_, e) => logger.write_object(e)
  }
}
