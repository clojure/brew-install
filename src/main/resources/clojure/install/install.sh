#!/usr/bin/env bash

prefix="$1"

# default config file
cp deps.edn "$prefix"
cp example-deps.edn "$prefix"
cp tools.edn "$prefix"

# jar needed by scripts
mkdir -p "$prefix/libexec"
cp ./*.jar "$prefix/libexec"

# scripts
${HOMEBREW_RUBY_PATH} -pi.bak -e "gsub(/PREFIX/, '$prefix')" clojure
${HOMEBREW_RUBY_PATH} -pi.bak -e "gsub(/BINDIR/, '$prefix/bin')" clj
mkdir -p "$prefix/bin"
cp clojure "$prefix/bin"
cp clj "$prefix/bin"

# man pages
mkdir -p "$prefix/share/man/man1"
cp clojure.1 "$prefix/share/man/man1"
cp clj.1 "$prefix/share/man/man1"
