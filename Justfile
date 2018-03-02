ci:
    @hlint .
    @yamllint .hlint.yaml
    @yamllint .stylish-haskell.yaml

ghcjs:
    rm -f ~/.local/bin/cabal
    rm -rf ~/.ghcjs
    /opt/ghc/bin/cabal new-install cabal-install --constraint='cabal-install == 1.24.0.2' --symlink-bindir ~/.local/bin
    cabal install https://github.com/matchwood/ghcjs-stack-dist/raw/master/ghcjs-0.2.1.9008011.tar.gz -w ghc-8.0.2 --force-reinstalls
    export PATH=$HOME/.local/bin:$PATH && ghcjs-boot --with-ghc=ghc-8.0.2 --with-ghc-pkg=ghc-pkg-8.0.2

size:
    @sn d target/all.min.js

build:
    @./shake

script:
    @rm -f rm .ghc.environment.x86_64-linux-8.2.1
    @mkdir -p .shake
    @cp shake.hs .shake
    @cd .shake && ghc-8.2.2 -O2 shake.hs -o build
    @mv .shake/build .

view: build
    firefox-trunk target/index.html
