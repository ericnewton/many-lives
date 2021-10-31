#! /bin/bash
for dir in c++ clojure java python scala ; do
  echo '***********'
  echo "${dir}"
  echo '***********'
  ( cd "${dir}" ; ./run.sh )
done
