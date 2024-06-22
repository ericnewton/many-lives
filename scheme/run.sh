#! /bin/bash
fail() {
   echo $* 1>&2
   exit 1
}
which guile > /dev/null || fail you must install guile
echo 'guile'
sed "s/'chicken/'guile/" < life.scm > guile-life.scm
guile --use-srfi=1,69 guile-life.scm

which chicken-install > /dev/null || fail you must install chicken
echo 'chicken scheme'
chicken-install -verbose srfi-69
chicken-install -verbose srfi-1
csc -R chicken.time -R srfi-69 -R srfi-1 -R chicken.format life.scm
./life
