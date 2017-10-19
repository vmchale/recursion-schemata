build: script
    ./shake

script:
    mkdir -p .shake
    cp shake.hs .shake
    cd .shake && ghc -O2 shake.hs -o shake
    mv .shake/shake .

deploy:
    cp target/* ~/programming/rust/nessa-site/static/recursion-scheme-generator

clean:
    sn c .
    rm -rf target/ tags .shake shake

view:
    ./shake.hs
    firefox-trunk target/index.html
