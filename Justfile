#github-docs:
#    cp -r target/ docs/

deploy:
    cp target/* ~/programming/rust/nessa-site/static/recursion-scheme-generator

script:
    cp shake.hs .shake/shake.hs
    cd .shake && ghc -O2 shake.hs -o shake && cp shake ../

clean:
    sn c .
    rm -rf target/ tags .shake

view:
    ./shake.hs
    firefox-trunk target/index.html
