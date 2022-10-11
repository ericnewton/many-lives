#! /bin/bash
python3 life/life2.py ../rle/acorn.rle 
if ! python3 life/life.py ../rle/acorn.rle ; then
    echo you must have python3 installed
    exit 1
fi
python3 life/life2.py ../rle/acorn.rle 
