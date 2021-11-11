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
| sort -n
