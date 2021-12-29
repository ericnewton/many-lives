#! /bin/bash

wc  \
./c++/life.cpp \
./python/life/life.py \
./clojure/src/life/core.clj \
./java/src/main/java/newton/eric/c/App.java \
./scala/src/main/scala/Main.scala \
./go/module/life.go \
./haskell/life.hs \
./javascript/life.js \
./racket/life.rkt \
u/ruby/ruby.rb \
./rust/life/src/main.rs \
./elixir/life.exs \
./kotlin/src/main/kotlin/Main.kt \
./zig/life.zig \
./ocaml/life.ml \
./c/life.c \
./swift/life.swift \
| sort -n
