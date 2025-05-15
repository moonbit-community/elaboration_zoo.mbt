///|
fn conv(len : Lvl, t : Val, u : Val) -> Bool {
  /// 看到有 `appCl(t,VVar(len))` 就需要意识到，这是用 eta expansion, 是对 `body` 进行 normalize 了。
  /// 在依赖类型中， `Pi type` 也可以产生 `binder` 的，并不只有 `lambda expression` 才会有 `binder`。
  ///
  /// 当然在 Haskell 开启 (RankNTypes)[https://wiki.haskell.org/Rank-N_types] 后，arrow type 也可以有 binder.
  ///
  /// https://gitlab.haskell.org/haskell/prime/-/wikis/RankNTypes
  /// https://downloads.haskell.org/ghc/latest/docs/users_guide/exts/rank_polymorphism.html#extension-RankNTypes
  match (t, u) {
    (VU, VU) => true
    (VPi(_, a, b), VPi(_, a_, b_)) =>
      conv(len, a, a_) &&
      conv(len + 1, appCl(b, VVar(len)), appCl(b_, VVar(len)))
    (VLam(_, t), VLam(_, t_)) =>
      conv(len + 1, appCl(t, VVar(len)), appCl(t_, VVar(len)))
    (VLam(_, t), u) => conv(len + 1, appCl(t, VVar(len)), VApp(u, VVar(len)))
    (u, VLam(_, t)) => conv(len + 1, VApp(u, VVar(len)), appCl(t, VVar(len)))
    (VVar(x), VVar(x_)) => x == x_
    (VApp(t, u), VApp(t_, u_)) => conv(len, t, t_) && conv(len, u, u_)
    _ => false
  }
}

///|
/// 
/// 双向类型检查的参考资料
/// 
/// https://dl.acm.org/doi/10.1145/3450952
/// 
/// https://davidchristiansen.dk/tutorials/nbe/
/// 
/// https://davidchristiansen.dk/tutorials/bidirectional.pdf
/// 
fn check(raw : Raw, a : VTy, ctx~ : Ctx) -> Tm raise TypeError {
  match (raw, a) {
    (RSrcPos(pos, t), a) => check(t, a, ctx={ ..ctx, pos, })
    (RLam(x, t), VPi(x_, a, b)) =>
      Lam(x, check(t, appCl(b, VVar(ctx.lvl)), ctx=bind(x, a, ctx)))
    //                                           ^^^^
    // 双向类型检查最重要的部分就是把 binder 的类型添加到 ctx 里面
    (RLet(x, a, t, u), a_) => {
      let a = check(a, VU, ctx~)
      let va = eval(a, ctx.env)
      let t = check(t, va, ctx~)
      let vt = eval(t, ctx.env)
      let u = check(u, a_, ctx=define_(x, vt, va, ctx))
      //                       ^^^^^^^
      Let(x, a, t, u)
    }
    _ => {
      let (t, tty) = infer(raw, ctx~)
      if not(conv(ctx.lvl, tty, a)) {
        report(
          ctx.pos,
          $| type mismatch 
          $|
          $| expected type:
          $|
          $| \{quote(a,ctx.lvl)}
          $|
          $|
          $| inferred type:
          $|
          $| 
          $| \{quote(tty,ctx.lvl)}
          $| 
          ,
        )
      }
      t
    }
  }
}

///|
fn infer(raw : Raw, ctx~ : Ctx) -> (Tm, VTy) raise TypeError {
  match raw {
    RLet(x, a, t, u) => {
      let a = check(a, VU, ctx~)
      let va = eval(a, ctx.env)
      let t = check(t, va, ctx~)
      let vt = eval(t, ctx.env)
      let (u, uty) = infer(u, ctx=define_(x, vt, va, ctx))
      //                          ^^^^^^^
      (Let(x, a, t, u), uty)
    }
    RPi(x, a, b) => {
      let a = check(a, VU, ctx~)
      let b = check(b, VU, ctx=bind(x, eval(a, ctx.env), ctx))
      (Pi(x, a, b), VU)
    }
    RApp(t, u) => {
      let (t, tty) = infer(t, ctx~)
      match tty {
        VPi(_, a, b) => {
          let u = check(u, a, ctx~)
          (App(t, u), appCl(b, eval(u, ctx.env)))
        }
        tty =>
          report(
            ctx.pos,
            $| Expected a function type, instead inferred:
            $|
            $| \{quote(tty,ctx.lvl)}
            ,
          )
      }
    }
    RLam(_) => report(ctx.pos, "Can't infer type for lambda expression")
    RVar(x) =>
      loop (0, ctx.types) {
        (i, Empty) => report(ctx.pos, "variable out of scope: \{x}")
        (i, More((x_, a), tail=tys)) =>
          if x == x_ {
            (Var(Ix(i)), a)
          } else {
            continue (i + 1, tys)
          }
      }
    RU => (U, VU)
    RSrcPos(pos, t) => infer(t, ctx={ ..ctx, pos, })
  }
}

///|
fn bind(x : Name, a : VTy, ctx : Ctx) -> Ctx {
  let { env, types, lvl, pos } = ctx
  Ctx::{
    env: cons(VVar(lvl), env),
    types: cons((x, a), types),
    lvl: lvl + 1,
    pos,
  }
}

///|
fn define_(x : Name, t : Val, a : VTy, ctx : Ctx) -> Ctx {
  let { env, types, lvl, pos } = ctx
  Ctx::{ env: cons(t, env), types: cons((x, a), types), lvl: lvl + 1, pos }
}

///|
fn[A] report(pos : SourcePos, x : String) -> A raise TypeError {
  raise TypeError(pos, x)
}
