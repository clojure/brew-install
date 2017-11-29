#!/usr/bin/env bash

set -e

echo "Downloading and expanding tar"
curl -O https://download.clojure.org/install/clojure-scripts-${project.version}.tar.gz
tar xzf clojure-scripts-${project.version}.tar.gz

echo "Installing libs into /usr/local/lib/clojure"
mkdir -p /usr/local/lib/clojure
cp -f clojure-scripts/deps.edn clojure-scripts/example-deps.edn /usr/local/lib/clojure
mkdir -p /usr/local/lib/clojure/libexec
cp -f clojure-scripts/clojure-scripts-${project.version}.jar /usr/local/lib/clojure/libexec

echo "Installing clojure and clj into /usr/local/bin"
sed -i -e 's@PREFIX@/usr/local/lib/clojure@g' clojure-scripts/clojure
cp -f clojure-scripts/clojure clojure-scripts/clj /usr/local/bin

echo "Removing download"
rm -rf clojure-scripts
rm -rf clojure-scripts-${project.version}.tar.gz

echo "Use clj -h for help."
