#! /bin/bash
fail() {
   echo $* 1>&2
   exit 1
}
which chicken-install > /dev/null || fail you must install chicken
echo 'chicken scheme'
chicken-install -verbose srfi-69
chicken-install -verbose srfi-1
chicken-install -verbose srfi-18
csc -R chicken.time -R srfi-69 -R srfi-1 -R srfi-18 -R chicken.format life.scm
./life

which guile > /dev/null || fail you must install guile
echo 'guile'
guile --use-srfi=1,18,69 life.scm

