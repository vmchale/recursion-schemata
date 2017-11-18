ghcjs:
    cabal install https://github.com/matchwood/ghcjs-stack-dist/raw/master/ghcjs-0.2.1.9008011.tar.gz -w ghc-8.0.2

size:
    @sn d target/all.min.js

build:
    @./shake

script:
    @rm -f rm .ghc.environment.x86_64-linux-8.2.1
    @mkdir -p .shake
    @cp shake.hs .shake
    @cd .shake && ghc -O2 shake.hs -o shake
    @mv .shake/shake .

view: build
    firefox-trunk target/index.html
