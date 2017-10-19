# recursion scheme generator

Try it out [here](http://vmchale.com/recursion-scheme-generator/index.html).
Written using the [miso](https://haskell-miso.org) framework and the
[Madlang](https://github.com/vmchale/madlang) language.

## Building

Install the following:

  * [just](https://github.com/casey/just)
  * [stack](https://docs.haskellstack.org/en/stable/README/)
  * [cabal](https://www.haskell.org/cabal/download.html)
  * [ghc](https://www.haskell.org/ghc/download.html)
  * [ccjs](https://www.npmjs.com/package/closure-compiler)

Then:

```bash
 $ cabal update
 $ cabal install shake
 $ just build
```

## Contents

```
-------------------------------------------------------------------------------
 Language            Files        Lines         Code     Comments       Blanks
-------------------------------------------------------------------------------
 Cabal                   1           52           45            3            4
 CSS                     1           32           28            0            4
 Haskell                 4          151          118            4           29
 HTML                    1           10           10            0            0
 Madlang                 1          105           79            4           22
 Markdown                1            5            5            0            0
 YAML                    2           24           24            0            0
-------------------------------------------------------------------------------
 Total                  11          379          309           11           59
-------------------------------------------------------------------------------
```
