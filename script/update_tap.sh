#!/bin/bash

set -e

# Checkout tap repo - done by action
# git clone git@github.com:clojure/homebrew-tools.git target/homebrew-tools

echo "Update repo tap to add version $VERSION"

# Copy in the new formulas
cp target/clojure.rb target/homebrew-tools/Formula
cp "target/clojure@$VERSION.rb" target/homebrew-tools/Formula

# Commit
cd target/homebrew-tools
git add Formula/clojure.rb "Formula/clojure@$VERSION.rb"
git commit -m "Publish $VERSION"
git push
cd ../..
