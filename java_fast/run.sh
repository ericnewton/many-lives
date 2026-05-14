#! /bin/bash 

javac $(find src -name '*.java')
java -cp src manylives.Main

