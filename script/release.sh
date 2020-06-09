#!/bin/bash

set -e

# Grab version properties
version=$(mvn -B help:evaluate -Dexpression=project.version 2>/dev/null| grep -v "^\[")
version_short=${version//.}
clojure_version=$(mvn -B help:evaluate -Dexpression=clojure.version 2>/dev/null| grep -v "^\[")
tdeps_version=$(mvn -B help:evaluate -Dexpression=tools.deps.version 2>/dev/null| grep -v "^\[")
read stable_version stable_sha < stable.properties
echo "Building scripts version $version"

# Build uberjar and filter resources
echo "Building"
java -cp $(clojure -A:package -Spath) clojure.main -m build :build/version "$version" :clj/version-short "$version_short" :clj/stable-sha "$stable_sha" :clj/stable-version "$stable_version" :clj/clojure-version "$clojure_version" :clj/tdeps-version "$tdeps_version"

# Make tar file of jar and script
echo "Building scripts tar file"
mkdir -p target/clojure-tools
chmod +x target/resources/install.sh target/resources/linux-install.sh target/resources/clojure target/resources/clj
cp target/resources/clj target/resources/clojure target/resources/deps.edn target/resources/example-deps.edn target/resources/install.sh doc/clojure.1 target/clojure-tools
cp "target/clojure-tools-$version-standalone.jar" "target/clojure-tools/clojure-tools-$version.jar"
cp doc/clojure.1 target/clojure-tools/clj.1
tar -cvzf "target/clojure-tools-$version.tar.gz" -Ctarget clojure-tools

# Make zip file of jar and windows scripts
echo "Building scripts zip file"
mkdir -p target/win/ClojureTools
cp target/resources/ClojureTools.psd1 target/resources/ClojureTools.psm1 target/resources/deps.edn target/resources/example-deps.edn target/win/ClojureTools
cp "target/clojure-tools-$version-standalone.jar" "target/win/ClojureTools/clojure-tools-$version.jar"
cd target/win
zip -r "../clojure-tools-$version.zip" ClojureTools
cd ../..

# Create formula file (brew)
echo "Creating formula files"
cp target/resources/clojure.rb target
sha=$(shasum -a 256 "target/clojure-tools-$version.tar.gz" | cut -c 1-64)
perl -pi.bak -e "s,SHA,$sha,g" target/clojure.rb

cp target/resources/clojure@version.rb "target/clojure@$version.rb"
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
  aws s3 cp --only-show-errors "target/resources/linux-install.sh" "$S3_BUCKET/install/linux-install.sh"
  aws s3 cp --only-show-errors "target/resources/linux-install.sh" "$S3_BUCKET/install/linux-install-$version.sh"
  echo "Deploying https://download.clojure.org/install/clojure-tools-$version.zip"
  aws s3 cp --only-show-errors "target/clojure-tools-$version.zip" "$S3_BUCKET/install/clojure-tools.zip"
  aws s3 cp --only-show-errors "target/clojure-tools-$version.zip" "$S3_BUCKET/install/clojure-tools-$version.zip"
  echo "Deploying https://download.clojure.org/install/win-install-$version.ps1"
  aws s3 cp --only-show-errors "target/resources/win-install.ps1" "$S3_BUCKET/install/win-install.ps1"
  aws s3 cp --only-show-errors "target/resources/win-install.ps1" "$S3_BUCKET/install/win-install-$version.ps1"
fi
