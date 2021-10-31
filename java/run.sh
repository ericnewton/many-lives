#! /bin/bash
export JAVA_HOME=/opt/homebrew/opt/openjdk
echo "building (and hiding maven output, see /tmp/build)"
mvn package -DskipTests assembly:single >/tmp/buld 2>&1 &&
echo running &&
java -Djdk.attach.allowAttachSelf=true -jar target/life-1.0-SNAPSHOT-jar-with-dependencies.jar
