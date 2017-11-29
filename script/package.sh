#!/bin/bash

set -e

# Clean
echo "Cleaning"
rm -rf target

# Grab version
version=$(mvn -B help:evaluate -Dexpression=project.version 2>/dev/null| grep -v "^\[")
echo "Building scripts version $version"

# Build uberjar and filter resources
echo "Building uberjar"
mvn -B clean package -Dmaven.test.skip=true

# Make tar file of jar and script
echo "Building scripts tar file"
mkdir -p target/clojure-scripts
chmod +x target/classes/clojure target/classes/clj target/classes/install.sh target/classes/linux-install.sh
cp target/classes/clojure target/classes/clj target/classes/deps.edn target/classes/example-deps.edn target/classes/install.sh "target/clojure-scripts-$version.jar" target/clojure-scripts
tar -cvzf "target/clojure-scripts-$version.tar.gz" -Ctarget clojure-scripts

# Create formula file
echo "Creating formula file"
cp target/classes/clojure.rb target
sha=$(shasum -a 256 "target/clojure-scripts-$version.tar.gz" | cut -c 1-64)
perl -pi.bak -e "s,SHA,$sha,g" target/clojure.rb

# Deploy to s3
if [[ ! -z "$S3_BUCKET" ]]; then
  echo "Deploying https://download.clojure.org/install/clojure-scripts-$version.tar.gz"
  aws s3 cp --only-show-errors "target/clojure-scripts-$version.tar.gz" "$S3_BUCKET/install/clojure-scripts.tar.gz"
  aws s3 cp --only-show-errors "target/clojure-scripts-$version.tar.gz" "$S3_BUCKET/install/clojure-scripts-$version.tar.gz"
  echo "Deploying https://download.clojure.org/install/clojure-$version.rb"
  aws s3 cp --only-show-errors "target/clojure.rb" "$S3_BUCKET/install/clojure.rb"
  aws s3 cp --only-show-errors "target/clojure.rb" "$S3_BUCKET/install/clojure-$version.rb"
  echo "Deploying https://download.clojure.org/install/linux-install.sh"
  aws s3 cp --only-show-errors "target/classes/linux-install.sh" "$S3_BUCKET/install/linux-install.sh"
  aws s3 cp --only-show-errors "target/classes/linux-install.sh" "$S3_BUCKET/install/linux-install-$version.sh"
fi
