///|
let next_meta : Ref[Int] = Ref::new(0)

///|
/// meta context 是全局变量， 和 local context是不同的
let mctx : Ref[@immut/sorted_map.T[Int, MetaEntry]] = Ref::new(
  @immut/sorted_map.new(),
)

///|
fn reset() -> Unit {
  next_meta.val = 0
  mctx.val = @immut/sorted_map.new()
}

///|
fn lookupMeta(mv : MetaVar) -> MetaEntry {
  let ms = mctx
  match ms.val.get(mv.to_int()) {
    None => abort("impossible")
    Some(e) => e
  }
}

///|
fn vMeta(mv : MetaVar) -> Val {
  match lookupMeta(mv) {
    Solved(v) => v
    Unsolved => VFlex(mv, @list.empty())
  }
}

///|
fn force(val : Val) -> Val {
  match val {
    VFlex(m, sp) =>
      match lookupMeta(m) {
        Solved(t) => force(vAppSp(t, sp))
        _ => val
      }
    _ => val
  }
}

///|
fn quoteSp(len : Lvl, t : Tm, sp : Spine) -> Tm {
  sp.to_array().rev_fold(init=t, (acc, x) => App(acc, quote(x, len)))
}

///|
fn freshMeta(ctx : Ctx) -> Tm {
  let m = next_meta.val
  next_meta.val = m + 1 // 这里会产生 UUID
  mctx.val = mctx.val.add(m, Unsolved)
  InsertedMeta(MetaVar(m), ctx.bds)
}

///|
struct PartialRenaming {
  dom : Lvl // Gamma
  cod : Lvl // Delta
  ren : @immut/sorted_map.T[Int, Lvl]
  // mapping from Delta to Gamma
  // TODO use Array
} derive(Show)

///|
fn PartialRenaming::lift(self : PartialRenaming) -> PartialRenaming {
  let { dom, cod, ren } = self
  { dom: dom + 1, cod: cod + 1, ren: ren.add(cod.to_int(), dom) }
}

/// A problem is a pattern unification problem if the following hold:
///
/// 1. spine consists of distinct bound variables
/// 2. every free variable of rhs occurs in spine
/// 3. ?α does not occur in rhs
///
/// https://github.com/AndrasKovacs/elaboration-zoo/blob/master/03-holes/Main.hs#L95-L99
///
/// 简单来说
/// 
/// 1. `Spine` 里面都是 `VVar`
/// 2. rhs 的所有的自由变量， 都出现在 `Spine`里面
/// 3. 禁止自引用

///|
fn invert(gamma : Lvl, sp : Spine) -> PartialRenaming raise {
  fn go(sp : Spine) -> (Lvl, @immut/sorted_map.T[Int, Lvl]) raise {
    match sp {
      Empty => (Lvl(0), @immut/sorted_map.new())
      More(t, tail=sp) => {
        let (dom, ren) = go(sp)
        match force(t) {
          VRigid(Lvl(x), _) if not(ren.contains(x)) =>
            (dom + 1, ren.add(x, dom))
          _ => raise UnifyError("spine has non variables")
        }
      }
    }
  }

  let (dom, ren) = go(sp)
  PartialRenaming::{ dom, cod: gamma, ren }
}

///|
fn vVar(x : Lvl) -> Val {
  VRigid(x, @list.empty())
}

///|
fn rename(m : MetaVar, pren : PartialRenaming, v : Val) -> Tm raise {
  letrec goSp = fn(pren : PartialRenaming, t : Tm, sp : Spine) -> Tm raise {
    match sp {
      Empty => t
      More(u, tail=sp) => {
        let u = go(pren, u)
        let sp = goSp(pren, t, sp)
        App(sp, u)
      }
    }
  }
  and go = fn(pren : PartialRenaming, t : Val) -> Tm raise {
    match force(t) {
      VPi(x, a, b) =>
        Pi(x, go(pren, a), go(pren.lift(), appCl(b, vVar(pren.cod))))
      VLam(x, t) => Lam(x, go(pren.lift(), appCl(t, vVar(pren.cod))))
      VRigid(Lvl(x), sp) =>
        match pren.ren.get(x) {
          None => raise UnifyError("scope error")
          Some(x_) => goSp(pren, Var(x_.to_ix(pren.dom)), sp)
        }
      VFlex(m_, sp) =>
        if m == m_ {
          raise UnifyError("occurs check")
        } else {
          goSp(pren, Meta(m_), sp)
        }
      VU => U
    }
  }

  go(pren, v)
}

///|
fn lams(l : Lvl, t : Tm) -> Tm {
  fn go(x, t) {
    if x == l {
      t
    } else {
      Lam("x\{x.to_int() + 1}", go(x + 1, t))
    }
  }

  go(Lvl(0), t)
}

///|
/// 简单来说 solve 就是把 `?a x y w z ?= rhs` 变成 `?a ?= fun x y w z -> rhs` 的程序，
/// 除此之外，需要满足上面的三个要求
/// 
fn solve(gamma : Lvl, m : MetaVar, sp : Spine, rhs : Val) -> Unit raise {
  let pren = invert(gamma, sp)
  let rhs = rename(m, pren, rhs)
  let solution = eval(lams(pren.dom, rhs), @list.empty())
  mctx.val = mctx.val.add(m.to_int(), Solved(solution))
}

///|
fn unifySp(l : Lvl, sp : Spine, sp_ : Spine) -> Unit raise {
  match (sp, sp_) {
    (Empty, Empty) => ()
    (More(t, tail=sp), More(t_, tail=sp_)) => {
      unifySp(l, sp, sp_)
      unify(l, t, t_)
    }
    _ => raise UnifyError("rigid mismatch error")
  }
}

///|
fn unify(l : Lvl, t : Val, u : Val) -> Unit raise {
  match (force(t), force(u)) {
    (VLam(_, t), VLam(_, t_)) =>
      unify(l + 1, appCl(t, vVar(l)), appCl(t_, vVar(l)))
    (t, VLam(_, t_)) => unify(l + 1, vApp(t, vVar(l)), appCl(t_, vVar(l)))
    (VLam(_, t), t_) => unify(l + 1, appCl(t, vVar(l)), vApp(t_, vVar(l)))
    (VU, VU) => ()
    (VPi(_, a, b), VPi(_, a_, b_)) => {
      unify(l, a, a_)
      unify(l + 1, appCl(b, vVar(l)), appCl(b_, vVar(l)))
    }
    (VRigid(x, sp), VRigid(x_, sp_)) if x == x_ => unifySp(l, sp, sp_)
    (VFlex(m, sp), VFlex(m_, sp_)) if m == m_ => unifySp(l, sp, sp_)
    (VFlex(m, sp), t_) => solve(l, m, sp, t_)
    (t, VFlex(m_, sp_)) => solve(l, m_, sp_, t)
    _ => raise UnifyError("rigid mismatch error")
  }
}

///|
fn unifyCatch(t : Val, t_ : Val, ctx~ : Ctx) -> Unit raise {
  unify(ctx.lvl, t, t_) catch {
    _ => raise Error_(ctx, CantUnify(quote(t, ctx.lvl), quote(t_, ctx.lvl)))
  }
}

///|
let emptyCtx : Ctx = Ctx::default()

///|
fn bind(ctx : Ctx, x : Name, a : VTy) -> Ctx {
  let { lvl, env, types, bds, pos } = ctx
  Ctx::{
    env: cons(vVar(lvl), env),
    lvl: lvl + 1,
    types: cons((x, a), types),
    bds: cons(Bound, bds),
    pos,
  }
}

///|
fn define_(ctx : Ctx, x : Name, t : Val, a : VTy) -> Ctx {
  let { lvl, env, types, bds, pos } = ctx
  Ctx::{
    env: cons(t, env),
    lvl: lvl + 1,
    types: cons((x, a), types),
    bds: cons(Defined, bds),
    pos,
  }
}

///|
fn closeVal(ctx : Ctx, t : Val) -> Closure {
  Closure(ctx.env, quote(t, ctx.lvl + 1))
}

///|
fn check(raw : Raw, aTy : Vty, ctx~ : Ctx) -> Tm raise {
  match (raw, force(aTy)) {
    (RSrcPos(pos, t), a) => check(t, a, ctx={ ..ctx, pos, })
    (RLam(x, t), VPi(_, a, b)) => {
      let t = check(t, appCl(b, vVar(ctx.lvl)), ctx=bind(ctx, x, a))
      Lam(x, t)
    }
    (RLet(x, a, t, u), a_) => {
      let a = check(a, VU, ctx~)
      let va = eval(a, ctx.env)
      let t = check(t, va, ctx~)
      let vt = eval(t, ctx.env)
      let u = check(u, a_, ctx=define_(ctx, x, vt, va))
      Let(x, a, t, u)
    }
    (RHole, a) => freshMeta(ctx)
    (t, expected) => {
      let (t, inferred) = infer(t, ctx~)
      unifyCatch(expected, inferred, ctx~)
      t
    }
  }
}

///|
fn infer(t : Raw, ctx~ : Ctx) -> (Tm, Vty) raise {
  match t {
    RSrcPos(pos, t) => infer(t, ctx={ ..ctx, pos, })
    RVar(x) =>
      loop (Ix(0), ctx.types) {
        (Ix(idx), Empty) => raise NameNotInScope(x, ctx.types.map(x => x.0))
        (Ix(idx), More((x_, a), tail=types)) => {
          guard x != x_ else { (Var(idx), a) }
          continue (Ix(idx + 1), types)
        }
      }
    RLam(x, t) => {
      let a = eval(freshMeta(ctx), ctx.env)
      let (t, b) = infer(t, ctx=bind(ctx, x, a))
      (Lam(x, t), VPi(x, a, closeVal(ctx, b)))
    }
    RLet(x, a, t, u) => {
      let a = check(a, VU, ctx~)
      let va = eval(a, ctx.env)
      let t = check(t, va, ctx~)
      let vt = eval(t, ctx.env)
      let (u, b) = infer(u, ctx=define_(ctx, x, vt, va))
      (Let(x, a, t, u), b)
    }
    RPi(x, a, b) => {
      let a = check(a, VU, ctx~)
      let b = check(b, VU, ctx=bind(ctx, x, eval(a, ctx.env)))
      (Pi(x, a, b), VU)
    }
    RU => (U, VU)
    RApp(t, u) => {
      let (t, tty) = infer(t, ctx~)
      let (a, b) = match force(tty) {
        VPi(x, a, b) => (a, b)
        tty => {
          let a = eval(freshMeta(ctx), ctx.env)
          let b = Closure(ctx.env, freshMeta(bind(ctx, "x", a)))
          unifyCatch(VPi("x", a, b), tty, ctx~)
          (a, b)
        }
      }
      let u = check(u, a, ctx~)
      (App(t, u), appCl(b, eval(u, ctx.env)))
    }
    RHole => {
      let a = eval(freshMeta(ctx), ctx.env)
      let t = freshMeta(ctx)
      (t, a)
    }
  }
}
