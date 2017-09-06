#!/usr/bin/env bash

prefix="$1"

cp ./*.jar "$prefix/libexec"
cp deps.edn "$prefix"
ruby -pi.bak -e "gsub(/PREFIX/, '$prefix')" clojure
cp clojure "$prefix/bin"
cp clj "$prefix/bin"
