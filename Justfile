deploy:
    cp target/* ~/programming/rust/nessa-site/static/recursion-scheme-generator

clean:
    sn c .
    rm -rf target/ tags .shake

view:
    ./shake.hs
    firefox-trunk target/index.html
