#! /bin/bash
for dir in c++ clojure haskell java javascript python scala ; do
  echo '***********'
  echo "${dir}"
  echo '***********'
  ( cd "${dir}" ; ./run.sh )
done
