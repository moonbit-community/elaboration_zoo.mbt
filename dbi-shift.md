# De Bruijn index

## Abstract Syntax Trees

AST 在 substitute 的时候需要注意 `CAS(capture avoiding substitution)`, 我们可以先对 AST 进行 `fresh renaming`，就不用担心 CAS 了

## Abstract Binding Trees

1. High-Other Abstract Syntax
2. De Bruijn index

本文主要讲解 DBI 的 `shift` 操作

这里我们介绍 binder 的 notation

$\lambda x.M$, 这个是 lambda abstraction

$\lambda x$ 被称为 binder。
[Lambda Calculus](https://en.wikipedia.org/wiki/Lambda_calculus)

DBI 是和 binder 的距离

下面提供一些例子，这里和 wiki 不同，这里是从 0 开始的

| --                                         | nameless representation               |
| ------------------------------------------ | ------------------------------------- |
| $\lambda x.x$                              | $\lambda 0$                           |
| $\lambda x.\lambda y. x + y$               | $\lambda.\lambda.1 + 0$               |
| $\lambda x.\lambda y.\lambda z. x + y + x$ | $\lambda .\lambda .\lambda.2 + 1 + 0$ |

我们可以对这个 binder 所 bound 的变量进行替换

### Var

| --                | nameless representation |
| ----------------- | ----------------------- |
| $[x \mapsto z]x $ | $[0 \mapsto 999] 0 $    |
| z                 | 999                     |

如何 x 是 free variable 就可以替换

### Abs

| -                          | nameless representation        |
| -------------------------- | ------------------------------ |
| $[x \mapsto z]\lambda y.x$ | $[0 \mapsto 999]\lambda.1$     |
| $\lambda y.[x \mapsto z]x$ | $\lambda . [1 \mapsto 1000] 1$ |
| $\lambda y.z$              | $\lambda.1000$                 |

这里我们注意到，outer context 的 dbi 进入 binding 之后都 +1 了，这里的 x 和 z 的 index 都变成 index + 1

### App

#### example 1

| step | --                            | nameless representation      |
| ---- | ----------------------------- | ---------------------------- |
| 0    | $(\lambda x.x) y$             | $(\lambda.0)999$             |
| 1    | $\lambda x. [x \mapsto y](x)$ | $\lambda. [0 \mapsto 1000]0$ |
| 2    | $\lambda x. y$                | $\lambda. 1000$              |
| 3    | y                             | $999$                        |

step $0\rightarrow 1$: 对 binding 里面的 body 进行替换，outer context 的 index 进入 binding 需要 +1, 这里只有 y 的 index 变成 index + 1, 因为 x 是 binder, 本来就在 binding 里面

step $2\rightarrow 3$: 去掉一层 binder, 同样离开 binding 需要 -1

貌似和 [Var rule](#var) 一样，但是每次进入一次 binding 会 +1，而 app 只会消除一层 binding,

#### example 2

| step | --                         | nameless representation                 |
| ---- | -------------------------- | --------------------------------------- |
| 0    | $(\lambda x.\lambda y.x)s$ | $\lambda. [0 \mapsto 1000](\lambda .1)$ |
| 1    |                            | $\lambda. \lambda. [1 \mapsto 1001]1$   |
| 2    |                            | $\lambda. \lambda. 1001$                |
| 3    | $\lambda y.s$              | $\lambda. 1000$                         |

step $0 \rightarrow 1$: 用 [abs rule](#abs), 两个一起递增
step $1 \rightarrow 2$: 用 [var rule](#var), 直接替换！
step $2 \rightarrow 3$: 最后去掉一层 binding，然后再递减

这个是**错误**示范，没有递增

| --                          | nameless representation     |
| --------------------------- | --------------------------- |
| $(\lambda x.\lambda y.x)s $ | $(\lambda .\lambda. 1) 999$ |
| $\lambda y.s$               | $\lambda.999$               |

term application 和 substitute 是不太一样的，不能混为一谈...

[tapl 的实现](https://www.cis.upenn.edu/~bcpierce/tapl/)

```ocaml
let termSubstTop s t =
  termShift (-1) (termSubst 0 (termShift 1 s) t)
```

因为 term application 会去掉一层 binding，所以这里才会 -1 的

进入 n 层 binding 需要+n,

### Conclusion

这里对 index 进行递增递减的操作称为 shift,

[j -> s]M, 我们仅对 s 进行 shift,
同时，j 在进入 binding 的时候也会递增，这里最重要的是解释 wsm，需要 shift,

我们使用 substitute 的时候是用 term application, [最简单的情况](#var) 是不需要 shift 的，
但是如果里面有 lambda, **每次**进入 1 层需要 +1，进入 d 层需要+d, 而 application 只会去掉一层，-1,

在[example 1](#example-1)里面 +1 后 -1，什么都没有变 qwq

注意，为了简单起见，[这里](#var)没有考虑是否是 free var，是否可以替换的情况，本文目的主要是解释 wsm，需要 shift

具体内容可以看 `TAPL 6.2 Shifting and Substitution`

## Related Links

[TAPL](https://www.cis.upenn.edu/~bcpierce/tapl/)

[AST with Scope](https://zhuanlan.zhihu.com/p/75073557)

[前置知识：De Bruijn Index](https://zhuanlan.zhihu.com/p/94601499)
