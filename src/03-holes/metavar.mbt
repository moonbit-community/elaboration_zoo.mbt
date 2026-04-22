///|
pub(all) struct MetaVar(Int) derive(Eq)

///|
fn MetaVar::to_int(self : MetaVar) -> Int = "%identity"

///|
impl Show for MetaVar with output(self, logger) {
  logger.write_string("MetaVar(")
  logger.write_object(self.to_int())
  logger.write_char(')')
}

///|
fn MetaVar::new(x : Int) -> MetaVar = "%identity"

///|
fn metavar(i : Int) -> MetaVar {
  MetaVar::new(i)
}
