#! /bin/bash

if ! sbcl --version > /dev/null ; then
    echo 'install sbcl' 
    exit 1
fi
sbcl --script life.lisp
./life
