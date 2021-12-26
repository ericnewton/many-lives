#! /bin/bash
if ! ocamlopt --version >/dev/null 2>&1 ; then
   echo "you must install ocamlopt"
   exit 1;
fi
ocamlopt unix.cmxa -O3 -o life life.ml && ./life
