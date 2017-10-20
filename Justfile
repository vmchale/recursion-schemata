size:
    @sn d target/all.min.js

build:
    @./shake

script:
    @mkdir -p .shake
    @cp shake.hs .shake
    cd .shake && ghc -O2 shake.hs -o shake
    @mv .shake/shake .

deploy: build
    cp target/* ~/programming/rust/nessa-site/static/recursion-scheme-generator

view: build
    firefox-trunk target/index.html
