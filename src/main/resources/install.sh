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
        ;;
    Darwin*)
        install=$(command -v ginstall 2>&1 || { echo >&2 "ginstall command not found. Please install coreutils package. Aborting."; exit 1; })
esac

default_prefix_dir="/usr/local"
use_local=

while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        # path prefix where clojure will be installed
        -p|--prefix)
            if [[ -z "$2" ]]; then
                do_usage
            else
                prefix_dir="$2"
            fi
            shift # past argument
            shift # past value
            ;;
        # argument to skip downloading and expanding archive with the tool, install will use current dir instead.
        # mainly for packaging needs so should not be mentioned in usage notes.
        -l|--local)
            use_local=true
            shift # past argument
            ;;
        *) # unknown option
            do_usage
            ;;
    esac
done

if [ $use_local = true ]; then
    # Set dir containing the installed files
    SCRIPT="${BASH_SOURCE[0]}"
    while [ -h "$SCRIPT" ]; do # resolve $SCRIPT until the file is no longer a symlink
        TARGET="$(readlink "$SCRIPT")"
        if [[ $TARGET == /* ]]; then
            SCRIPT="$TARGET"
        else
            DIR="$( dirname "$SCRIPT" )"
            SCRIPT="$DIR/$TARGET" # if $SCRIPT was a relative symlink, we need to resolve it relative to the path where the symlink file was located
        fi
    done
    tools_dir="$( cd -P "$( dirname "$SCRIPT" )" >/dev/null 2>&1 && pwd )"
else
    tools_dir=clojure-tools
    echo "Downloading and expanding tar"
    curl -O https://download.clojure.org/install/clojure-tools-${project.version}.tar.gz
    tar xzf clojure-tools-${project.version}.tar.gz
fi

lib_dir="$prefix_dir/lib"
bin_dir="$prefix_dir/bin"
man_dir="$prefix_dir/share/man/man1"
clojure_lib_dir="$lib_dir/clojure"

echo "Installing libs into $clojure_lib_dir"
$install -Dm644 "$tools_dir/deps.edn" "$clojure_lib_dir/deps.edn"
$install -Dm644 "$tools_dir/example-deps.edn" "$clojure_lib_dir/example-deps.edn"
$install -Dm644 "$tools_dir/clojure-tools-${project.version}.jar" "$clojure_lib_dir/libexec/clojure-tools-${project.version}.jar"

echo "Installing clojure and clj into $bin_dir"
$install -Dm755 "$tools_dir/clojure" "$bin_dir/clojure"
$install -Dm755 "$tools_dir/clj" "$bin_dir/clj"

echo "Installing man pages into $man_dir"
$install -Dm644 "$tools_dir/clojure.1" "$man_dir/clojure.1"
$install -Dm644 "$tools_dir/clj.1" "$man_dir/clj.1"

if [ ! use_local = true ]; then
    echo "Removing download"
    rm -rf clojure-tools
    rm -rf clojure-tools-${project.version}.tar.gz
fi

echo "Use clj -h for help."
