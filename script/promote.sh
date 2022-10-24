#!/bin/bash

set -e

# Grab version info
read stable_version stable_sha < stable.properties
read devel_version devel_sha < devel.properties
echo "Promoting stable from $stable_version to $devel_version"

# Checkout tap repo
rm -rf target
mkdir target
git clone git@github.com:clojure/homebrew-tools.git target/homebrew-tools

# Update the formula to replace stable with devel
perl -pi.bak -e "s,$stable_version,$devel_version,g" target/homebrew-tools/Formula/clojure.rb
perl -pi.bak -e "s,$stable_sha,$devel_sha,g" target/homebrew-tools/Formula/clojure.rb
rm target/homebrew-tools/Formula/clojure.rb.bak

# Commit
cd target/homebrew-tools
git add Formula/clojure.rb
git commit --allow-empty -m "Promote $devel_version to stable"
git push
cd ../..

# Move devel properties to stable
cp devel.properties stable.properties

git add stable.properties
git commit -m "update stable to $devel_version"

# Publish stable version file
if [[ ! -z "$S3_BUCKET" ]]; then
  echo "Deploying https://download.clojure.org/install/stable.properties"
  aws s3 cp --only-show-errors "stable.properties" "$S3_BUCKET/install/stable.properties"
fi
