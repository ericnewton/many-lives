#! /bin/bash
for dir in \
    c \
    c++ \
    clojure \
    csharp \
    elixir \
    go \
    haskell \
    java \
    javascript \
    kotlin \
    ocaml \
    python \
    racket \
    ruby \
    rust \
    scala \
    swift \
    typed-racket \
    zig ; do
  echo '***********'
  echo "${dir}"
  echo '***********'
  ( cd "${dir}" ; ./run.sh )
done
