#! /bin/bash
if ! zig version 2>&1 /dev/null 
then
  echo you need to install zig 
  exit 1
fi
make clean life && ./life
