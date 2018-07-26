import           Data.Maybe
import           Data.Monoid
import           Development.Shake
import           Development.Shake.Cabal
import           Development.Shake.ClosureCompiler
import           Development.Shake.Command
import           Development.Shake.FileDetect
import           Development.Shake.FilePath
import           Development.Shake.Linters
import           Development.Shake.Util
import           System.Directory
import qualified System.IO.Strict                  as Strict

main :: IO ()
main = shakeArgs shakeOptions { shakeFiles = ".shake", shakeLint = Just LintBasic } $ do
    want [ "target/index.html", "README.md" ]

    "deploy" ~> do
        need [ "target/index.html", "target/all.min.js" ]
        cmd ["ion", "-c", "cp target/* ~/programming/rust/nessa-site/static/recursion-scheme-generator"]

    "clean" ~> do
        putNormal "cleaning files..."
        unit $ cmd ["rm", "-rf", "tags", "build"]
        removeFilesAfter "target" ["//*"]
        removeFilesAfter "dist" ["//*"]
        removeFilesAfter "dist-newstyle" ["//*"]
        removeFilesAfter ".shake" ["//*"]

    "README.md" %> \out -> do
        hs <- getHs ["src", "app"]
        yaml <- getYml
        cabal <- getDirectoryFiles "" ["//*.cabal"]
        mad <- getMadlang
        html <- getDirectoryFiles "" ["web-src//*.html"]
        css <- getDirectoryFiles "" ["web-src//*.css"]
        need $ hs <> yaml <> cabal <> mad <> html <> css
        (Stdout out) <- cmd ["poly"]
        file <- liftIO $ Strict.readFile "README.md"
        let header = takeWhile (/= replicate 79 '-') $ lines file
        let new = unlines header ++ out ++ "```\n"
        liftIO $ writeFile "README.md" new

    "dist-newstyle/build/x86_64-linux/ghcjs-0.2.1.9008011/recursion-scheme-generator-0.1.0.0/x/recursion-scheme-generator/opt/build/recursion-scheme-generator/recursion-scheme-generator.jsexe/all.js" %> \out -> do
        need . snd =<< getCabalDepsA "recursion-scheme-generator.cabal"
        madlang =<< getMadlang
        cmd ["cabal", "new-build"]

    googleClosureCompiler ["dist-newstyle/build/x86_64-linux/ghcjs-0.2.1.9008011/recursion-scheme-generator-0.1.0.0/x/recursion-scheme-generator/opt/build/recursion-scheme-generator/recursion-scheme-generator.jsexe/all.js"] "target/all.min.js"

    "target/styles.css" %> \out -> do
        liftIO $ createDirectoryIfMissing True "target"
        need ["web-src/styles.css"]
        cmd ["cp","web-src/styles.css", "target/styles.css"]

    "target/index.html" %> \out -> do
        need ["target/all.min.js", "target/styles.css"]
        cmd ["cp","web-src/index.html", "target/index.html"]
