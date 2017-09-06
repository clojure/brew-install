#!/usr/bin/env bash

prefix="$1"

# default config file
cp deps.edn "$prefix"

# jar needed by scripts
mkdir "$prefix/libexec"
cp ./*.jar "$prefix/libexec"

# scripts
ruby -pi.bak -e "gsub(/PREFIX/, '$prefix')" clojure
mkdir "$prefix/bin"
cp clojure "$prefix/bin"
cp clj "$prefix/bin"
