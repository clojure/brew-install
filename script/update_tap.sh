#!/bin/bash

set -e

# Checkout tap repo - done by action
# git clone git@github.com:clojure/homebrew-tools.git target/homebrew-tools

version=`cat VERSION`
echo "Update repo tap to add version $version"

# Copy in the new formulas
cp target/clojure.rb target/homebrew-tools/Formula
cp "target/clojure@$version.rb" target/homebrew-tools/Formula

# Commit
cd target/homebrew-tools
git add Formula/clojure.rb "Formula/clojure@$version.rb"
git commit -m "Publish $version"
git push
cd ../..
