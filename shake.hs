import           Data.Maybe
import           Data.Monoid
import           Development.Shake
import           Development.Shake.Command
import           Development.Shake.FilePath
import           Development.Shake.Util
import           System.Directory
import qualified System.IO.Strict           as Strict

main :: IO ()
main = shakeArgs shakeOptions { shakeFiles = ".shake", shakeLint = Just LintBasic } $ do
    want [ "target/index.html", "README.md" ]

    "deploy" ~> do
        need [ "target/index.html" ]
        cmd ["ion", "-c", "cp target/* ~/programming/rust/nessa-site/static/recursion-scheme-generator"]

    "clean" ~> do
        putNormal "cleaning files..."
        unit $ cmd ["rm", "-rf", "tags"]
        removeFilesAfter "target" ["//*"]
        cmd ["stack", "clean"]

    "README.md" %> \out -> do
        hs <- getDirectoryFiles "" ["src//*.hs"]
        yaml <- getDirectoryFiles "" ["//*.yaml"]
        cabal <- getDirectoryFiles "" ["//*.cabal"]
        mad <- getDirectoryFiles "" ["//*.mad"]
        html <- getDirectoryFiles "" ["web-src//*.html"]
        css <- getDirectoryFiles "" ["web-src//*.css"]
        need $ hs <> yaml <> cabal <> mad <> html <> css
        (Stdout out) <- cmd ["tokei", ".", "-e", "README.md", "-e", "TODO.md", "-e", "target", "-e", "Justfile"]
        file <- liftIO $ Strict.readFile "README.md"
        let header = takeWhile (/= replicate 79 '-') $ lines file
        let new = unlines header ++ out ++ "```\n"
        liftIO $ writeFile "README.md" new
        cmd ["rm", "-f", "README.md.original"]

    "purge" ~> do
        putNormal "purging local files..."
        unit $ cmd ["rm", "-rf", "tags", "shake"]
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
