#!/usr/bin/env cabal
{- cabal:
build-depends: base, shake, shake-cabal, shake-google-closure-compiler, shake-ext, directory, strict
default-language: Haskell2010
-}

import           Development.Shake
import           Development.Shake.Cabal
import           Development.Shake.ClosureCompiler
import           Development.Shake.FileDetect
import           Development.Shake.Linters
import           System.Directory
import qualified System.IO.Strict                  as Strict

main :: IO ()
main = shakeArgs shakeOptions { shakeFiles = ".shake", shakeLint = Just LintBasic } $ do
    want [ "target/index.html", "README.md" ]

    "deploy" ~> do
        need [ "target/index.html", "target/all.min.js" ]
        cmd ["ion", "-c", "cp target/* ~/programming/rust/nessa-site/static/recursion-scheme-generator"]

    "clean" ~> do
        unit $ cmd ["rm", "-rf", "tags", "build", "mad-src/tags"]
        removeFilesAfter "target" ["//*"]
        removeFilesAfter "dist" ["//*"]
        removeFilesAfter "dist-newstyle" ["//*"]
        removeFilesAfter ".shake" ["//*"]

    "README.md" %> \out -> do
        let getThisDirectory = getDirectoryFiles ""
        hs <- getHs ["src"]
        yaml <- getYml
        mad <- getMadlang
        cabal <- getThisDirectory ["//*.cabal"]
        html <- getThisDirectory ["web-src//*.html"]
        css <- getThisDirectory ["web-src//*.css"]
        need $ hs <> yaml <> cabal <> mad <> html <> css
        (Stdout out') <- cmd ["poly", "-c"]
        file <- liftIO $ Strict.readFile "README.md"
        let header = takeWhile (/= replicate 79 '-') $ lines file
        let new = unlines header ++ out' ++ "```\n"
        liftIO $ writeFile out new

    "dist-newstyle/build/x86_64-linux/ghcjs-0.2.1.9008011/recursion-scheme-generator-0.1.0.0/x/recursion-scheme-generator/opt/build/recursion-scheme-generator/recursion-scheme-generator.jsexe/all.js" %> \_ -> do
        need . snd =<< getCabalDepsA "recursion-scheme-generator.cabal"
        madlang =<< getMadlang
        cmd ["cabal", "new-build", "--ghcjs"]

    googleClosureCompiler ["dist-newstyle/build/x86_64-linux/ghcjs-0.2.1.9008011/recursion-scheme-generator-0.1.0.0/x/recursion-scheme-generator/opt/build/recursion-scheme-generator/recursion-scheme-generator.jsexe/all.js"] "target/all.min.js"

    "target/styles.css" %> \out -> do
        liftIO $ createDirectoryIfMissing True "target"
        need ["web-src/styles.css"]
        copyFile' "web-src/styles.css" out

    "target/index.html" %> \out -> do
        need ["target/all.min.js", "target/styles.css"]
        copyFile' "web-src/index.html" out
