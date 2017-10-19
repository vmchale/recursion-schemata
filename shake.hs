#!/usr/bin/env stack
{- stack --resolver lts-9.9 --install-ghc
    runghc
    --package shake
    --package directory
    --package strict
    --stack-yaml stack-shake.yaml
-}

import           Data.Maybe
import           Data.Monoid
import           Development.Shake
import           Development.Shake.Command
import           Development.Shake.FilePath
import           Development.Shake.Util
import           System.Directory
import qualified System.IO.Strict                      as Strict
--
import           Data.Version
import           Distribution.Package
import           Distribution.PackageDescription
import           Distribution.PackageDescription.Parse
import           Distribution.Verbosity

version :: IO String
version = do
    generic <- readPackageDescription normal "recursion-scheme-generator.cabal"
    pure . showVersion . pkgVersion . package . packageDescription $ generic

main :: IO ()
main = version >>= \v -> shakeArgs shakeOptions { shakeFiles = ".shake", shakeLint = Just LintBasic, shakeVersion = v } $ do
    want [ "target/index.html", "README.md" ]

    "clean" ~> do
        putNormal "cleaning files..."
        unit $ cmd ["rm", "-rf", "tags"]
        removeFilesAfter "target" ["//*"]
        cmd ["stack", "clean"]

    "README.md" %> \out -> do
        hs <- getDirectoryFiles "" ["//*.hs"]
        yaml <- getDirectoryFiles "" ["//*.yaml"]
        cabal <- getDirectoryFiles "" ["//*.cabal"]
        mad <- getDirectoryFiles "" ["//*.mad"]
        html <- getDirectoryFiles "" ["//*.html"]
        css <- getDirectoryFiles "" ["//*.css"]
        need $ hs <> yaml <> cabal <> mad <> html <> css
        (Stdout out) <- cmd ["tokei", ".", "-e", "README.md", "-e", "target/"]
        file <- liftIO $ Strict.readFile "README.md"
        let header = takeWhile (/= replicate 79 '-') $ lines file
        let new = unlines header ++ out ++ "```\n"
        liftIO $ writeFile "README.md" new
        cmd ["rm", "-f", "README.md.original"]

    "purge" ~> do
        putNormal "purging local files..."
        unit $ cmd ["rm", "-rf", "tags"]
        removeFilesAfter ".stack-work" ["//*"]
        removeFilesAfter ".shake" ["//*"]
        removeFilesAfter "target" ["//*"]

    ".stack-work/dist/x86_64-linux/Cabal-1.24.2.0_ghcjs/build/recursion-scheme-generator/recursion-scheme-generator.jsexe/all.js" %> \out -> do
        need ["src/Lib.hs","recursion-scheme-generator.cabal","stack.yaml","mad-src/recursion-schemes.mad"]
        -- check the recursion-schemes.mad file so we don't push anything wrong
        unit $ cmd ["bash", "-c", "madlang debug mad-src/recursion-schemes.mad > /dev/null"]
        cmd ["stack", "build", "--stack-yaml", "stack.yaml", "--install-ghc"]

    ".stack-work/dist/x86_64-linux/Cabal-1.24.2.0_ghcjs/build/recursion-scheme-generator/recursion-scheme-generator.jsexe/all.min.js" %> \out -> do
        need [".stack-work/dist/x86_64-linux/Cabal-1.24.2.0_ghcjs/build/recursion-scheme-generator/recursion-scheme-generator.jsexe/all.js"]
        cmd (Cwd ".stack-work/dist/x86_64-linux/Cabal-1.24.2.0_ghcjs/build/recursion-scheme-generator/recursion-scheme-generator.jsexe/") Shell "ccjs all.js --externs=node --externs=all.js.externs > all.min.js"

    "target/all.min.js" %> \out -> do
        need [".stack-work/dist/x86_64-linux/Cabal-1.24.2.0_ghcjs/build/recursion-scheme-generator/recursion-scheme-generator.jsexe/all.min.js"]
        cmd Shell "cp .stack-work/dist/x86_64-linux/Cabal-1.24.2.0_ghcjs/build/recursion-scheme-generator/recursion-scheme-generator.jsexe/all.min.js target/all.min.js"

    "target/styles.css" %> \out -> do
        liftIO $ createDirectoryIfMissing True "target"
        need ["web-src/styles.css"]
        cmd ["cp","web-src/styles.css", "target/styles.css"]

    "target/index.html" %> \out -> do
        need ["target/all.min.js", "target/styles.css"]
        cmd ["cp","web-src/index.html", "target/index.html"]
