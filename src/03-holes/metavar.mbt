///|
pub(all) struct MetaVar(Int) derive(Show, Eq)

///|
fn MetaVar::to_int(self : MetaVar) -> Int = "%identity"

///|
fn MetaVar::new(x : Int) -> MetaVar = "%identity"

///|
fnalias MetaVar::new as metavar
