#!/usr/bin/env bash

prefix="$1"

# default config file
cp deps.edn "$prefix"
cp example-deps.edn "$prefix"

# jar needed by scripts
mkdir -p "$prefix/libexec"
cp ./*.jar "$prefix/libexec"

# scripts
# ${HOMEBREW_RUBY_PATH} is the full path name of a ruby executable,
# installed internally within Homebrew's files, both on a Linux system
# that does not have ruby installed anywhere else, and on a macOS system
# that already had /usr/bin/ruby installed before Homebrew was installed.
${HOMEBREW_RUBY_PATH} -pi.bak -e "gsub(/PREFIX/, '$prefix')" clojure
mkdir -p "$prefix/bin"
cp clojure "$prefix/bin"
cp clj "$prefix/bin"

# man pages
mkdir -p "$prefix/share/man/man1"
cp clojure.1 "$prefix/share/man/man1"
cp clj.1 "$prefix/share/man/man1"
