# De Bruijn index

## Abstract Syntax Trees

When performing substitution on AST, we need to pay attention to `CAS(capture avoiding substitution)`. We can first perform `fresh renaming` on the AST to avoid worrying about CAS.

## Abstract Binding Trees

1. High-Other Abstract Syntax
2. De Bruijn index

This article mainly explains the `shift` operation of DBI.

Here we introduce the notation for binders.

$\lambda x.M$, this is lambda abstraction

$\lambda x$ is called a binder.
[Lambda Calculus](https://en.wikipedia.org/wiki/Lambda_calculus)

DBI is the distance from the binder.

Here are some examples. Unlike the wiki, we start from 0 here.

| --                                         | nameless representation               |
| ------------------------------------------ | ------------------------------------- |
| $\lambda x.x$                              | $\lambda 0$                           |
| $\lambda x.\lambda y. x + y$               | $\lambda.\lambda.1 + 0$               |
| $\lambda x.\lambda y.\lambda z. x + y + x$ | $\lambda .\lambda .\lambda.2 + 1 + 0$ |

We can substitute the variables bound by this binder.

### Var

| --                | nameless representation |
| ----------------- | ----------------------- |
| $[x \mapsto z]x $ | $[0 \mapsto 999] 0 $    |
| z                 | 999                     |

If x is a free variable, it can be substituted.

### Abs

| -                          | nameless representation        |
| -------------------------- | ------------------------------ |
| $[x \mapsto z]\lambda y.x$ | $[0 \mapsto 999]\lambda.1$     |
| $\lambda y.[x \mapsto z]x$ | $\lambda . [1 \mapsto 1000] 1$ |
| $\lambda y.z$              | $\lambda.1000$                 |

Here we notice that the dbi of the outer context is incremented by 1 when entering the binding. The index of both x and z becomes index + 1.

### App

#### example 1

| step | --                            | nameless representation      |
| ---- | ----------------------------- | ---------------------------- |
| 0    | $(\lambda x.x) y$             | $(\lambda.0)999$             |
| 1    | $\lambda x. [x \mapsto y](x)$ | $\lambda. [0 \mapsto 1000]0$ |
| 2    | $\lambda x. y$                | $\lambda. 1000$              |
| 3    | y                             | $999$                        |

step $0\rightarrow 1$: Substitute in the body of the binding. The index of the outer context needs to be incremented by 1 when entering the binding. Here only y's index becomes index + 1, because x is a binder and is already inside the binding.

step $2\rightarrow 3$: Remove one layer of binder. Similarly, leaving the binding requires -1.

It seems the same as the [Var rule](#var), but entering each binding requires +1, while application only eliminates one layer of binding.

#### example 2

| step | --                         | nameless representation                 |
| ---- | -------------------------- | --------------------------------------- |
| 0    | $(\lambda x.\lambda y.x)s$ | $\lambda. [0 \mapsto 1000](\lambda .1)$ |
| 1    |                            | $\lambda. \lambda. [1 \mapsto 1001]1$   |
| 2    |                            | $\lambda. \lambda. 1001$                |
| 3    | $\lambda y.s$              | $\lambda. 1000$                         |

step $0 \rightarrow 1$: Use [abs rule](#abs), increment both together.
step $1 \rightarrow 2$: Use [var rule](#var), substitute directly!
step $2 \rightarrow 3$: Finally remove one layer of binding, then decrement.

This is a **wrong** example, without incrementing:

| --                          | nameless representation     |
| --------------------------- | --------------------------- |
| $(\lambda x.\lambda y.x)s $ | $(\lambda .\lambda. 1) 999$ |
| $\lambda y.s$               | $\lambda.999$               |

Term application and substitution are not the same and should not be confused...

[TAPL implementation](https://www.cis.upenn.edu/~bcpierce/tapl/)

```ocaml
let termSubstTop s t =
  termShift (-1) (termSubst 0 (termShift 1 s) t)
```

Because term application removes one layer of binding, -1 is needed here.

Entering n layers of binding requires +n.

### Conclusion

The operation of incrementing/decrementing indices is called shift.

[j -> s]M, we only shift s.
Meanwhile, j also increments when entering bindings. The most important thing here is to explain why shift is needed.

When we use substitution, we use term application. The [simplest case](#var) doesn't need shift,
but if there are lambdas inside, entering 1 layer requires +1, entering d layers requires +d, while application only removes one layer, -1.

In [example 1](#example-1), +1 followed by -1, nothing changed.

Note: For simplicity, [here](#var) doesn't consider whether it's a free var or whether substitution is allowed. The main purpose of this article is to explain why shift is needed.

For detailed content, see `TAPL 6.2 Shifting and Substitution`.

## Related Links

[TAPL](https://www.cis.upenn.edu/~bcpierce/tapl/)

[AST with Scope](https://zhuanlan.zhihu.com/p/75073557)

[Prerequisites: De Bruijn Index](https://zhuanlan.zhihu.com/p/94601499)