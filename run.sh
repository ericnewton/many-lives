#! /bin/bash
for dir in c++ clojure go haskell java javascript kotlin python racket scala ; do
  echo '***********'
  echo "${dir}"
  echo '***********'
  ( cd "${dir}" ; ./run.sh )
done
