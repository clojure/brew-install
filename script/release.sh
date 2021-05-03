#!/bin/bash

set -e

# Clean
echo "Cleaning"
rm -rf target

# Grab version properties
version=$(mvn -B help:evaluate -Dexpression=project.version 2>/dev/null| grep -v "^\[")
version_short=${version//.}
read stable_version stable_sha < stable.properties
echo "Building scripts version $version"

# Build uberjar and filter resources
echo "Building"
mvn -e -B clean package "-Dversion.short=$version_short" "-Dstable.sha=$stable_sha" "-Dstable.version=$stable_version"

# Build exec jar
echo "Building exec jar"
mkdir -p target/clojure-tools
jar cf target/clojure-tools/exec.jar -C target/classes clojure/run/exec.clj

# Make tar file of jar and script
echo "Building scripts tar file"
chmod +x target/classes/clojure/install/clojure target/classes/clojure/install/clj target/classes/clojure/install/install.sh target/classes/clojure/install/linux-install.sh
cp target/classes/clojure/install/clojure target/classes/clojure/install/clj target/classes/clojure/install/deps.edn target/classes/clojure/install/example-deps.edn target/classes/clojure/install/tools.edn target/classes/clojure/install/install.sh "target/clojure-tools-$version.jar" doc/clojure.1 target/clojure-tools
cp "target/clojure-tools-$version.jar" "target/clojure-tools/clojure-tools-$version.jar"
cp doc/clojure.1 target/clojure-tools/clj.1
tar -cvzf "target/clojure-tools-$version.tar.gz" -Ctarget clojure-tools

# Make zip file of jar and windows scripts
echo "Building scripts zip file"
mkdir -p target/win/ClojureTools
cp target/classes/clojure/install/ClojureTools.psd1 target/classes/clojure/install/ClojureTools.psm1 target/classes/clojure/install/deps.edn target/classes/clojure/install/example-deps.edn target/classes/clojure/install/tools.edn "target/clojure-tools-$version.jar" target/win/ClojureTools
cp target/clojure-tools/exec.jar target/win/ClojureTools
cd target/win
zip -r "../clojure-tools.zip" ClojureTools
cd ../..
cp target/classes/clojure/install/win-install.ps1 target

# Create formula file (brew)
echo "Creating formula files"
cp target/classes/clojure/install/clojure.rb target
sha=$(shasum -a 256 "target/clojure-tools-$version.tar.gz" | cut -c 1-64)
perl -pi.bak -e "s,SHA,$sha,g" target/clojure.rb

cp target/classes/clojure/install/clojure@version.rb "target/clojure@$version.rb"
perl -pi.bak -e "s,SHA,$sha,g" "target/clojure@$version.rb"

# Commit and deploy to s3
if [[ ! -z "$S3_BUCKET" ]]; then
  # Write devel properties
  echo "$version $sha" > devel.properties
  git add devel.properties
  git commit -m "update devel to $version"

  echo "Deploying https://download.clojure.org/install/clojure-tools-$version.tar.gz"
  aws s3 cp --only-show-errors "target/clojure-tools-$version.tar.gz" "$S3_BUCKET/install/clojure-tools.tar.gz"
  aws s3 cp --only-show-errors "target/clojure-tools-$version.tar.gz" "$S3_BUCKET/install/clojure-tools-$version.tar.gz"
  echo "Deploying https://download.clojure.org/install/clojure@$version.rb"
  aws s3 cp --only-show-errors "target/clojure.rb" "$S3_BUCKET/install/clojure.rb"
  aws s3 cp --only-show-errors "target/clojure@$version.rb" "$S3_BUCKET/install/clojure@$version.rb"
  echo "Deploying https://download.clojure.org/install/linux-install-$version.sh"
  aws s3 cp --only-show-errors "target/classes/clojure/install/linux-install.sh" "$S3_BUCKET/install/linux-install.sh"
  aws s3 cp --only-show-errors "target/classes/clojure/install/linux-install.sh" "$S3_BUCKET/install/linux-install-$version.sh"
  echo "Deploying https://download.clojure.org/install/clojure-tools-$version.zip"
  aws s3 cp --only-show-errors "target/clojure-tools.zip" "$S3_BUCKET/install/clojure-tools.zip"
  aws s3 cp --only-show-errors "target/clojure-tools.zip" "$S3_BUCKET/install/clojure-tools-$version.zip"
  echo "Deploying https://download.clojure.org/install/win-install-$version.ps1"
  aws s3 cp --only-show-errors "target/win-install.ps1" "$S3_BUCKET/install/win-install.ps1"
  aws s3 cp --only-show-errors "target/win-install.ps1" "$S3_BUCKET/install/win-install-$version.ps1"
fi
