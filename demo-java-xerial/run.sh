#!/usr/bin/env bash
# The Spring/Hibernate demo on xerial's sqlite-jdbc instead of ffm-sqlite-jdbc.
#
# This directory holds no Java source: it builds ../demo-hibernate-sqlite with -Pxerial, so the
# java row and this row compare the SAME application with a different JDBC driver.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export NAME="${NAME:-java-xerial}"
export STACK="${STACK:-OpenJDK27/Spring4.1/Hibernate7 (xerial sqlite-jdbc)}"
export PORT="${PORT:-8085}"
export NOTES="${NOTES:-same source as java, built with -Pxerial}"
export MVN_PROFILE="-Pxerial"
# The Docker image copies the java demo's run.sh and jar next to this script. On the host it
# builds in ../demo-hibernate-sqlite/target, so --native runs of both rows overwrite each other's jar.
if [ -x "$HERE/java-run.sh" ]; then exec "$HERE/java-run.sh" "$@"; fi
exec "$(dirname "$HERE")/demo-hibernate-sqlite/run.sh" "$@"
