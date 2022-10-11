#! /bin/bash
for runner in */test.sh
do
  dir=$(dirname $runner)
  echo '***********'
  echo "${dir}"
  echo '***********'
  ( cd "${dir}" ; ./test.sh )
done
