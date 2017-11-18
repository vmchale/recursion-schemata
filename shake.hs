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
        removeFilesAfter "dist-newstyle" ["//*"]
        removeFilesAfter "dist" ["//*"]
        removeFilesAfter ".shake" ["//*"]
        removeFilesAfter "target" ["//*"]

    "dist-newstyle/build/x86_64-linux/ghcjs-0.2.1.9008011/recursion-scheme-generator-0.1.0.0/c/recursion-scheme-generator/build/recursion-scheme-generator/recursion-scheme-generator.jsexe/all.js" %> \out -> do
        need ["src/Lib.hs","recursion-scheme-generator.cabal","cabal.project.local","mad-src/recursion-schemes.mad"]
        -- check the recursion-schemes.mad file so we don't push anything wrong
        unit $ cmd ["bash", "-c", "madlang check mad-src/recursion-schemes.mad > /dev/null"]
        cmd ["cabal", "new-build", "--ghcjs"]

    "dist-newstyle/build/x86_64-linux/ghcjs-0.2.1.9008011/recursion-scheme-generator-0.1.0.0/c/recursion-scheme-generator/build/recursion-scheme-generator/recursion-scheme-generator.jsexe/all.min.js" %> \out -> do
        need ["dist-newstyle/build/x86_64-linux/ghcjs-0.2.1.9008011/recursion-scheme-generator-0.1.0.0/c/recursion-scheme-generator/build/recursion-scheme-generator/recursion-scheme-generator.jsexe/all.js"]
        cmd (Cwd "dist-newstyle/build/x86_64-linux/ghcjs-0.2.1.9008011/recursion-scheme-generator-0.1.0.0/c/recursion-scheme-generator/build/recursion-scheme-generator/recursion-scheme-generator.jsexe") Shell "ccjs all.js --externs=node --externs=all.js.externs > all.min.js"

    "target/all.min.js" %> \out -> do
        need ["dist-newstyle/build/x86_64-linux/ghcjs-0.2.1.9008011/recursion-scheme-generator-0.1.0.0/c/recursion-scheme-generator/build/recursion-scheme-generator/recursion-scheme-generator.jsexe/all.min.js"]
        cmd Shell "cp dist-newstyle/build/x86_64-linux/ghcjs-0.2.1.9008011/recursion-scheme-generator-0.1.0.0/c/recursion-scheme-generator/build/recursion-scheme-generator/recursion-scheme-generator.jsexe/all.min.js target/all.min.js"

    "target/styles.css" %> \out -> do
        liftIO $ createDirectoryIfMissing True "target"
        need ["web-src/styles.css"]
        cmd ["cp","web-src/styles.css", "target/styles.css"]

    "target/index.html" %> \out -> do
        need ["target/all.min.js", "target/styles.css"]
        cmd ["cp","web-src/index.html", "target/index.html"]
