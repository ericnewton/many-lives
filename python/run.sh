#! /bin/bash
python3 life/life2.py ../rle/r-pentomino.rle
if ! python3 life/life.py ../rle/r-pentomino.rle ; then
    echo you must have python3 installed
    exit 1
fi
python3 life/life2.py ../rle/r-pentomino.rle 
