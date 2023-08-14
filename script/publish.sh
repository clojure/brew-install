#!/bin/bash

set -e

# Commit and deploy to s3
if [[ ! -z "$S3_BUCKET" ]]; then
  # Write devel properties
  version=$(cat VERSION)
  sha=$(shasum -a 256 "target/clojure-tools-$version.tar.gz" | cut -c 1-64)
  echo "$sha" > target/clojure-tools-$version.tar.gz.sha
  echo "$version $sha" > devel.properties
  git add devel.properties
  git commit -m "update devel to $version"

  echo "Deploying https://download.clojure.org/install/clojure@$version.rb"
  aws s3 cp --only-show-errors "target/clojure.rb" "$S3_BUCKET/install/clojure.rb"
  aws s3 cp --only-show-errors "target/clojure@$version.rb" "$S3_BUCKET/install/clojure@$version.rb"
  echo "Deploying https://download.clojure.org/install/clojure-tools-$version.tar.gz"
  aws s3 cp --only-show-errors "target/clojure-tools-$version.tar.gz" "$S3_BUCKET/install/clojure-tools.tar.gz"
  aws s3 cp --only-show-errors "target/clojure-tools-$version.tar.gz" "$S3_BUCKET/install/clojure-tools-$version.tar.gz"
  echo "Deploying https://download.clojure.org/install/linux-install-$version.sh"
  aws s3 cp --only-show-errors "target/linux-install.sh" "$S3_BUCKET/install/linux-install.sh"
  aws s3 cp --only-show-errors "target/linux-install.sh" "$S3_BUCKET/install/linux-install-$version.sh"
  echo "Deploying https://download.clojure.org/install/posix-install-$version.sh"
  aws s3 cp --only-show-errors "target/posix-install.sh" "$S3_BUCKET/install/posix-install.sh"
  aws s3 cp --only-show-errors "target/posix-install.sh" "$S3_BUCKET/install/posix-install-$version.sh"
  echo "Deploying https://download.clojure.org/install/clojure-tools-$version.zip"
  echo "$(shasum -a 256 target/clojure-tools.zip | cut -c 1-64)" > target/clojure-tools.zip.sha
  aws s3 cp --only-show-errors "target/clojure-tools.zip" "$S3_BUCKET/install/clojure-tools.zip"
  aws s3 cp --only-show-errors "target/clojure-tools.zip" "$S3_BUCKET/install/clojure-tools-$version.zip"
  echo "Deploying https://download.clojure.org/install/win-install-$version.ps1"
  aws s3 cp --only-show-errors "target/win-install.ps1" "$S3_BUCKET/install/win-install.ps1"
  aws s3 cp --only-show-errors "target/win-install.ps1" "$S3_BUCKET/install/win-install-$version.ps1"
fi
