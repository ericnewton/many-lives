#! /bin/bash
for runner in */run.sh
do
  dir=$(dirname $runner)
  echo '***********'
  echo "${dir}"
  echo '***********'
  ( cd "${dir}" ; ./run.sh )
done
