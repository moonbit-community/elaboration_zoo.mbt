## Guideline

* Rule 1: Do not define methods or use `dot syntax` when writing type checking related code.
* Rationale:
  * Overly ad-hoc code is inconvenient for code review.
  * When variable names are too short, using `dot syntax` looks very ugly.

     e.g. `t.eval(env~)` is uglier than `eval(t,env~)`.
  * When expressions are too complex, using `dot syntax` looks very ugly.
    Using `prefix apply` syntax looks better than `infix dot syntax` when writing complex expressions.
    e.g. `eval(u, cons(eval(t, env), env))` is uglier than `u.eval(cons(t.eval(env),env))`.

* Rule 2: `label argument` should always be placed at the last parameter position
* Rationale: Fixed parameter positions make code more consistent, and earlier parameters are generally more important


## Naming conventions

Function names use `lower camel case`

Common examples of expression naming

  `t`
  `(x : A) -> B`
  `t u`
  `let x : A = t in u`
  `A -> B`
  `fun x -> t`