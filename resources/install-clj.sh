#!/usr/bin/env bash

# Find java executable
JAVA_CMD=`type -p java`
if [[ ! -n "$JAVA_CMD" ]]; then
  if [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]; then
    JAVA_CMD="$JAVA_HOME/bin/java"
  else
    >&2 echo "Couldn't find 'java'. Please set JAVA_HOME."
  fi
fi

# Run initial dependency installer
"$JAVA_CMD" -classpath INSTALL_JAR clojure.tools.Install
