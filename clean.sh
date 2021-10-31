#! /bin/bash
find . -type f -name '*~' -delete
find . -name .idea | xargs rm -rf 
find . -type d -name target -print | xargs rm -rf
rm -f c++/life
