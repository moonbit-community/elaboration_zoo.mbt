///|
suberror TypeError String derive(Show)

///|
fn[A] report(x : String) -> A raise TypeError {
  raise TypeError(x)
}

///|
fn check(t : Raw, a : VTy, env~ : Env, ctx~ : Ctx) -> Unit raise TypeError {
  match (t, a) {
    (Lam(x, t), VPi(x_, a, b)) => {
      let x_ = fresh(env, x_)
      let env = env.prepend((x, VVar(x_)))
      let ctx = ctx.prepend((x, a))
      check(t, b(VVar(x_)), env~, ctx~)
    }
    (Let(x, a_, t_, u), _) => {
      check(a_, VU, env~, ctx~)
      let a_ = eval(a_, env)
      check(t_, a_, env~, ctx~)
      let res = {
        let env = env.prepend((x, eval(t_, env)))
        let ctx = ctx.prepend((x, a_))
        check(u, a, env~, ctx~)
      }
      res
    }
    _ => {
      let tty = infer(t, env~, ctx~)
      if not(conv(env, tty, a)) {
        report(
          (
            $| type mismatch 
            $|
            $| expected type:
            $|
            $| \{quote(a,env)}
            $|
            $|
            $| inferred type:
            $|
            $| 
            $| \{quote(tty,env)}
            $| 
          ),
        )
      }
    }
  }
}

///|
fn infer(t : Raw, env~ : Env, ctx~ : Ctx) -> VTy raise TypeError {
  match t {
    Pi(x, a, b) => {
      check(a, VU, env~, ctx~)
      {
        let env = env.add((x, VVar(x)))
        let ctx = ctx.add((x, eval(a, env)))
        check(b, VU, env~, ctx~)
      }
      VU
    }
    U => VU
    App(t, u) => {
      let tty = infer(t, env~, ctx~)
      match tty {
        VPi(_, a, b) => {
          check(u, a, env~, ctx~)
          b(eval(u, env))
        }
        _ =>
          report(
            "Expected a function type, instead inferred:\n\n \{quote(tty,env)}",
          )
      }
    }
    Lam(_) => report("Can't infer type for lambda expression")
    Var(x) =>
      match ctx.lookup(x) {
        Some(a) => a
        None => report("Name not in scope: \{x}")
      }
    Let(x, a, t, u) => {
      check(a, VU, env~, ctx~)
      let a = eval(a, env)
      check(t, a, env~, ctx~)
      let res = {
        let env = env.add((x, eval(t, env)))
        let ctx = ctx.add((x, a))
        infer(u, env~, ctx~)
      }
      res
    }
    SrcPos(_, t) => infer(t, env~, ctx~)
  }
}

///|
fn conv(env : Env, t : Val, u : Val) -> Bool {
  match (t, u) {
    (VU, VU) => true
    (VPi(x, a, b), VPi(x_, a_, b_)) => {
      let x = fresh(env, x)
      conv(env, a, a_) &&
      {
        let env = List::cons((x, VVar(x)), env)
        let b = b(VVar(x))
        let b_ = b_(VVar(x))
        conv(env, b, b_)
      }
    }
    (VLam(x, t), VLam(x_, t_)) => {
      let x = fresh(env, x)
      let env = List::cons((x, VVar(x)), env)
      let t = t(VVar(x))
      let t_ = t_(VVar(x))
      conv(env, t, t_)
    }
    // checking eta conversion for Lam
    (VLam(x, t), u) => {
      let x = fresh(env, x)
      let env = List::cons((x, VVar(x)), env)
      let lhs = t(VVar(x))
      let rhs = VApp(u, VVar(x))
      conv(env, lhs, rhs)
    }
    (u, VLam(x, t)) => {
      let x = fresh(env, x)
      let env = List::cons((x, VVar(x)), env)
      let lhs = t(VVar(x))
      let rhs = VApp(u, VVar(x))
      conv(env, lhs, rhs)
    }
    (VVar(x), VVar(x_)) => x == x_
    (VApp(t, u), VApp(t_, u_)) => conv(env, t, t_) && conv(env, u, u_)
    _ => false
  }
}

///|
test {
  let nil = nil()
  // \A x. x
  let id_tm = Lam("A", Lam("x", Var("x")))
  // forall A : U. forall _ : A. A
  let id_ty = eval(Pi("A", U, Pi("_", Var("A"), Var("A"))), nil)
  inspect(try? check(id_tm, id_ty, env=nil, ctx=nil), content="Ok(())")
  inspect(
    try? check(id_tm, VU, env=nil, ctx=nil),
    content=(
      #|Err(TypeError("Can't infer type for lambda expression"))
    ),
  )
  //  \A B x _. x
  let const_tm = Lam("A", Lam("B", Lam("x", Lam("_", Var("x")))))
  // forall A : U. 
  // forall B : U. 
  // forall _ : A. 
  // forall _ : B.
  // A
  let const_ty = eval(
    Pi("A", U, Pi("B", U, Pi("_", Var("A"), Pi("_", Var("B"), Var("A"))))),
    nil,
  )
  inspect(try? check(const_tm, const_ty, env=nil, ctx=nil), content="Ok(())")
}
