#!/usr/bin/env bash

set -euo pipefail

# Start
do_usage() {
  echo "Installs the Clojure command line tools."
  echo -e
  echo "Usage:"
  echo "linux-install.sh [-p|--prefix <dir>]"
  exit 1
}

default_prefix_dir="/usr/local"

# use getopt if the number of params grows
prefix_dir=$default_prefix_dir
prefix_param=${1:-}
prefix_value=${2:-}
if [[ "$prefix_param" = "-p" || "$prefix_param" = "--prefix" ]]; then
  if [[ -z "$prefix_value" ]]; then
    do_usage
  else
    prefix_dir="$prefix_value"
  fi
fi

echo "Downloading and expanding tar"
curl -O https://download.clojure.org/install/clojure-tools-${project.version}.tar.gz
tar xzf clojure-tools-${project.version}.tar.gz

lib_dir="$prefix_dir/lib"
bin_dir="$prefix_dir/bin"
man_dir="$prefix_dir/share/man/man1"
clojure_lib_dir="$lib_dir/clojure"

# we don't want to use -p because prefix dir should exist already, the prefix
# folder should not be created but the necessary subfolders should.

echo "Installing libs into $clojure_lib_dir"
[[ ! -d "$lib_dir" ]] && mkdir "$lib_dir"
[[ ! -d "$clojure_lib_dir" ]] && mkdir "$clojure_lib_dir"
cp -f clojure-tools/deps.edn clojure-tools/example-deps.edn "$clojure_lib_dir"
[[ ! -d "$clojure_lib_dir/libexec" ]] && mkdir "$clojure_lib_dir/libexec"
cp -f clojure-tools/clojure-tools-${project.version}.jar "$clojure_lib_dir/libexec"

echo "Installing clojure and clj into $bin_dir"
[[ ! -d "$bin_dir" ]] && mkdir "$bin_dir"
sed -i -e 's@PREFIX@'"$clojure_lib_dir"'@g' clojure-tools/clojure
cp -f clojure-tools/clojure clojure-tools/clj "$bin_dir"

echo "Installing man pages into $man_dir"
[[ ! -d "$man_dir" ]] && mkdir "$man_dir"
cp -f clojure-tools/clojure.1 "$man_dir"
cp -f clojure-tools/clj.1 "$man_dir"

echo "Removing download"
rm -rf clojure-tools
rm -rf clojure-tools-${project.version}.tar.gz

echo "Use clj -h for help."