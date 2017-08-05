#!/bin/bash

set -e

# Clean
echo "Cleaning"
rm -rf target

# Installer version
version=$(mvn help:evaluate -Dexpression=project.version 2>/dev/null| grep -v "^\[")
echo "Building installer version $version"

# Build uberjar and filter resources
echo "Building uberjar"
mvn clean package -Dmaven.test.skip=true

# Make tar file of jar and script
echo "Building installer tar file"
cp target/classes/clj.props target
cp target/classes/install-clj.sh target
cp target/classes/clj.sh target
tar -cvzf "target/install-clj-${version}.tar.gz" -Ctarget "install-clj-${version}.jar" clj.props install-clj.sh clj.sh

# Create formula file
echo "Creating formula file"
cp target/classes/clojure.rb target
sha=$(shasum -a 256 "target/install-clj-${version}.tar.gz" | cut -c 1-64)
sed -i '' "s/SHA/$sha/" target/clojure.rb
