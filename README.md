brew-install
=====================================

The brew-install project is used to create a brew formula for installing
clojure scripts on the Mac. The outputs of this project are a tar file
(versioned) and a brew formula (clojure.rb), suitable for updating in the 
brew central tap.

The tar file contains:

* clojure-scripts jar - an uberjar for constructing classpaths via tools.deps
* deps.edn - the initial user deps.edn file
* clojure script - the main Clojure runner
* clj script - a clojure wrapper for interactive repl use (adds rlwrap)

## Updating versions

The clojure-scripts version is defined by the pom.xml project version. It 
should be updated only by running script/build/update_version (the build does
this automatically).

The Clojure and tools.deps.alpha versions to include in the clojure-scripts are
defined in the pom.xml as properties and make their way from there into all the
other files via several means.

## Package script

The script/package.sh script is used to build the tar file and clojure.rb file.

## Release Information

These files are not released into Maven central like other libraries. Instead, the tar
file is created and published to https://download.clojure.org.

The clojure.rb file is then manually updated in the brew central tap via PR.

Release history:

* not yet released

## References

See the following resources for more information:

* https://github.com/clojure/tools.deps.alpha - dependency and classpath library

## Developer Information

* [GitHub project](https://github.com/clojure/brew-install)
* [How to contribute](https://dev.clojure.org/display/community/Contributing)
* [Bug Tracker](https://dev.clojure.org/jira/browse/INST)

## License

Copyright © 2017 Rich Hickey, Alex Miller and contributors

Distributed under the Eclipse Public License, the same as Clojure.
