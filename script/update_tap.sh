#!/bin/bash

set -e

echo "Building scripts version $version"

# Grab version
version=$(mvn -B help:evaluate -Dexpression=project.version 2>/dev/null| grep -v "^\[")

# Checkout tap repo
git clone git@github.com:clojure/homebrew-tools.git target/homebrew-tools

# Copy in the new formulas
cp target/clojure.rb target/homebrew-tools/Formula
cp "target/clojure@$version.rb" target/homebrew-tools/Formula

# Commit
cd target/homebrew-tools
git add Formula/clojure.rb "Formula/clojure@$version.rb"
git commit -m 'Publish $version'
git push
cd ../..
