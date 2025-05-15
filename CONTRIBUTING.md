## Guideline

* 规则 1：不定义方法和使用 `dot syntax` 在编写和类型检查相关的代码。 
* 理由： 
  * 过于 ad-hoc 的代码不方便 code review。
  * 当变量名过短的时候，使用 `dot syntax` 会非常丑。

     e.g. `t.eval(env~)` 比 `eval(t,env~)` 丑。
  * 当表达式过于复杂的时候，使用 `dot syntax` 会非常丑。
    使用 `prefix apply` 的语法在写复杂表达式会比用 `infix dot syntax` 好看。
    e.g. `eval(u, cons(eval(t, env), env))` 比 `u.eval(cons(t.eval(env),env))` 丑。

* 规则 2 `label argument` 永远放在最后的参数的位置
* 理由：固定参数位置可以让代码更加一致，前面的参数一般更重要


## Naming conventions

函数名使用 `lower camel case`

常见对表达式的命名例子

  `t`
  `(x : A) -> B`
  `t u`
  `let x : A = t in u`
  `A -> B`
  `fun x -> t`
