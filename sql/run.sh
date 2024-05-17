#! /usr/bin/env bash

set -eo pipefail
PORT=5432
DB=life

rm -rf data logfile
mkdir data
pg_ctl init -w -D data -s
pg_ctl -D data -l logfile start -w -o "-p 5432"
createdb "$DB"
/usr/bin/time -p sh -c "psql 'postgresql://localhost:$PORT/$DB' < life.sql >/dev/null 2>&1" |&  awk '/real / { print (1000 / $2) " generations / sec" }'
trap "pg_ctl stop -D data -w" EXIT
