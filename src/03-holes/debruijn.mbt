///|
type Ix Int derive(Show, Eq)

///|
impl Add for Ix with op_add(self, other) = "%i32_add"

///|
impl Sub for Ix with op_sub(self, other) = "%i32_sub"

///|
fn Ix::to_int(self : Ix) -> Int = "%identity"

///|
type Lvl Int derive(Show, Eq)

///|
impl Add for Lvl with op_add(self, other) = "%i32_add"

///|
impl Sub for Lvl with op_sub(self, other) = "%i32_sub"

///|
fn Lvl::to_ix(self : Lvl, len : Lvl) -> Ix {
  let l = len.inner()
  let x = self.inner()
  Ix(l - x - 1)
}

///|
fnalias Lvl::to_ix as lvl_to_ix

///|
fn Lvl::to_int(self : Lvl) -> Int = "%identity"
