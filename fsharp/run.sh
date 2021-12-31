#! /bin/bash
if ! dotnet --version >/dev/null 2>&1
then
   echo 'you need to install F# (dotnet)'
   exit 1
fi
cd life
exec dotnet run -c Release
