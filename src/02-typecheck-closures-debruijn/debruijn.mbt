///|
struct Ix(Int) derive(Eq)

///|
impl Add for Ix with add(self, other) = "%i32_add"

///|
impl Sub for Ix with sub(self, other) = "%i32_sub"

///|
fn Ix::to_int(self : Ix) -> Int = "%identity"

///|
pub impl Show for Ix with output(self, logger) {
  logger.write_string("Ix(")
  logger.write_object(self.to_int())
  logger.write_char(')')
}

///|
struct Lvl(Int) derive(Eq)

///|
impl Add for Lvl with add(self, other) = "%i32_add"

///|
impl Sub for Lvl with sub(self, other) = "%i32_sub"

///|

///|
fn Lvl::to_ix(self : Lvl, len : Lvl) -> Ix {
  let l = len.to_int()
  let x = self.to_int()
  Ix(l - x - 1)
}

///|
fn lvl_to_ix(lvl : Lvl, len : Lvl) -> Ix {
  lvl.to_ix(len)
}

///|
fn Lvl::to_int(self : Lvl) -> Int = "%identity"

///|
pub impl Show for Lvl with output(self, logger) {
  logger.write_string("Lvl(")
  logger.write_object(self.to_int())
  logger.write_char(')')
}
