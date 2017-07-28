#!/bin/bash

# Installer version
version=$(mvn help:evaluate -Dexpression=project.version 2>/dev/null| grep -v "^\[")

# Build uberjar and filter resources
mvn clean package -Dmaven.test.skip=true

# Make tar file of jar and script
cp target/classes/clj.props target
cp target/classes/install-clj.sh target
tar -cvzf "target/brew-install-${version}.tar.gz" -Ctarget "brew-install-${version}.jar" clj.props install-clj.sh

# Create formula file
cp target/classes/clojure.rb target
sha=$(shasum -a 256 "target/brew-install-${version}.tar.gz" | cut -c 1-64)
sed -i '' "s/SHA/$sha/" target/clojure.rb
