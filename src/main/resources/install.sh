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

case "$(uname -s)" in
    Linux*)
        install=$(which install)
        sed=$(which sed);;
    Darwin*)
        install=$(command -v ginstall 2>&1 || { echo >&2 "ginstall command not found. Please install coreutils package. Aborting."; exit 1; })
        sed=$(command -v gsed 2>&1 || { echo >&2 "gsed command not found. Please install gnu-sed package. Aborting."; exit 1; })
esac

default_prefix_dir="/usr/local"

# use getopt if the number of params grows
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -p|--prefix)
            if [[ -z "$2" ]]; then
                do_usage
            else
                prefix_dir="$2"
            fi
            shift # past argument
            shift # past value
            ;;
        *)    # unknown option
            do_usage
            ;;
    esac
done

echo "Downloading and expanding tar"
curl -O https://download.clojure.org/install/clojure-tools-${project.version}.tar.gz
tar xzf clojure-tools-${project.version}.tar.gz

lib_dir="$prefix_dir/lib"
bin_dir="$prefix_dir/bin"
man_dir="$prefix_dir/share/man/man1"
clojure_lib_dir="$lib_dir/clojure"

echo "Installing libs into $clojure_lib_dir"
$install -Dm644 clojure-tools/deps.edn "$clojure_lib_dir/deps.edn"
$install -Dm644 clojure-tools/example-deps.edn "$clojure_lib_dir/example-deps.edn"
$install -Dm644 clojure-tools/clojure-tools-${project.version}.jar "$clojure_lib_dir/libexec/clojure-tools-${project.version}.jar"

echo "Installing clojure and clj into $bin_dir"
$sed -i -e 's@PREFIX@'"$clojure_lib_dir"'@g' clojure-tools/clojure
$install -Dm755 clojure-tools/clojure "$bin_dir/clojure"
$install -Dm755 clojure-tools/clj "$bin_dir/clj"

echo "Installing man pages into $man_dir"
$install -Dm644 clojure-tools/clojure.1 "$man_dir/clojure.1"
$install -Dm644 clojure-tools/clj.1 "$man_dir/clj.1"

echo "Removing download"
rm -rf clojure-tools
rm -rf clojure-tools-${project.version}.tar.gz

echo "Use clj -h for help."
