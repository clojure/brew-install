#!/usr/bin/env bash

# Parse args
install_opts=()
while [ $# -gt 0 ]
do
  install_opts+=("$1")
  case "$1" in
    -v)
      verbose=true
      ;;
  esac
  shift
done

# Find java executable
JAVA_CMD=$(type -p java)
if [[ ! -n "$JAVA_CMD" ]]; then
  if [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]; then
    JAVA_CMD="$JAVA_HOME/bin/java"
  else
    >&2 echo "Couldn't find 'java'. Please set JAVA_HOME."
  fi
fi

install_dir=PREFIX

if [[ ! -d "$HOME/.clojure" ]]; then
  if [[ -n $verbose ]]; then echo "Creating $HOME/.clojure"; fi
  mkdir "$HOME/.clojure"
fi

if [[ -e "$HOME/.clojure/clj.props" ]]; then
  if [[ -n $verbose ]]; then echo "Backing up $HOME/.clojure/clj.props"; fi
  cp -f "$HOME/.clojure/clj.props" "$HOME/.clojure/clj.props.backup"
fi
if [[ -n $verbose ]]; then echo "Writing: $HOME/.clojure/clj.props"; fi
cp "$install_dir/clj.props" "$HOME/.clojure/clj.props"

# Run initial dependency installer
"$JAVA_CMD" -classpath "$install_dir/install-clj-${project.version}.jar" clojure.tools.Install "${install_opts[@]}"
