#!/bin/bash

# Set version
version=0.0.6

# Build
mvn clean package -Dmaven.test.skip=true

# Make tar file of jar and script
cp target/classes/clj.sh target
cp target/classes/install-clj.sh target
tar -cvzf target/clojure-install-bundle-${version}.tar.gz -Ctarget clojure-install-${version}.jar clj.sh install-clj.sh

# Create formula file
cp target/classes/clojure.rb target/clojure.rb
sha=`shasum -a 256 target/clojure-install-bundle-${version}.tar.gz | cut -c 1-64`
sed -i '' "s/SHA/$sha/" target/clojure.rb
