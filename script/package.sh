#!/bin/bash

# Set installer version
version=$(printf 'VER\t${project.version}' | mvn help:evaluate | grep '^VER' | cut -f2)
echo "brew-install version $version"

# Build uberjar
mvn clean package -Dmaven.test.skip=true

# Make tar file of jar and script
#cp resources/clj.sh target
#cp resources/install-clj.sh target
tar -cvzf target/brew-install-${version}.tar.gz -Ctarget brew-install-${version}.jar # clj.sh install-clj.sh

# Create formula file
cp resources/clojure.rb target/clojure.rb
sha=`shasum -a 256 target/brew-install-${version}.tar.gz | cut -c 1-64`
sed -i '' "s/SHA/$sha/" target/clojure.rb
