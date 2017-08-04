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

install_dir=PREFIX

if [[ ! -d "$HOME/.clojure" ]]; then
  echo "Creating $HOME/.clojure"
  mkdir "$HOME/.clojure"
fi

if [[ -e "$HOME/.clojure/clj.props" ]]; then
  echo "Backing up "$HOME/.clojure/clj.props"
  cp -f "$HOME/.clojure/clj.props" "$HOME/.clojure/clj.props.backup"
fi
echo "Writing: $HOME/.clojure/clj.props"
cp "$install_dir/clj.props" "$HOME/.clojure/clj.props"

# Run initial dependency installer
"$JAVA_CMD" -classpath "$install_dir/install-clj-${project.version}.jar" clojure.tools.Install
