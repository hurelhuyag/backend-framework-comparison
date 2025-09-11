#!/usr/bin/env bash

export JAVA_HOME=/home/hurlee/Apps/graalvm-jdk-24.0.2+11.1/
export PATH="$JAVA_HOME/bin:$PATH"

#mvn -DskipTests -Pnative clean package
#mvn -DskipTests -Pnative spring-boot:build-image
mvn -DskipTests -Pnative clean compile package native:compile