#! /bin/bash
JAR="target/consoleApp-1.0-SNAPSHOT-jar-with-dependencies.jar"
if [ ! -f "$JAR" ]
then
   mvn -B package
fi
java -jar "$JAR"
