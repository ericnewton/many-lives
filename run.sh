#! /bin/bash
for dir in \
    c \
    c++ \
    clojure \
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
    zig ; do
  echo '***********'
  echo "${dir}"
  echo '***********'
  ( cd "${dir}" ; ./run.sh )
done
