#!/bin/bash

set -e

# Grab version info
read stable_version stable_sha < stable.properties
read devel_version devel_sha < devel.properties
echo "Promoting stable from $stable_version to $devel_version"

export STABLE_VERSION=$stable_version
export STABLE_SHA=$stable_sha
export DEVEL_VERSION=$devel_version
export DEVEL_SHA=$devel_sha