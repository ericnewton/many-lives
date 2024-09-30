#! /bin/bash
echo "building (and hiding maven output, see /tmp/build)"
mvn package -DskipTests assembly:single >/tmp/build 2>&1 &&
echo running &&
java -Djdk.attach.allowAttachSelf=true -jar target/life-1.0-SNAPSHOT-jar-with-dependencies.jar
