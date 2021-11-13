#! /bin/bash
ghc --version >/dev/null || echo 1>&2 'You must have ghc installed'
make life
# use more CPUs: goes slower
export GHCRTS='-s -N'
# goes faster
export GHCRTS='-s'
./life 2>&1 | awk '/^ *Total/ { print 5000 / substr($5, 0, length($5) - 1), "generations / sec"}'

