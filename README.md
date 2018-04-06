brew-install
=====================================

The brew-install project is used to create a brew formula for installing
clojure tools on the Mac. The outputs of this project are a tar file
(versioned) and a brew formula (clojure.rb), suitable for updating in the 
brew central tap.

The tar file contains:

* clojure-tools jar - an uberjar for constructing classpaths via tools.deps
* deps.edn - the initial user deps.edn file
* clojure script - the main Clojure runner
* clj script - a clojure wrapper for interactive repl use (adds rlwrap)

## Updating versions

The clojure-tools version is defined by the pom.xml project version. It 
should be updated only by running script/build/update_version (the build does
this automatically).

The Clojure and tools.deps.alpha versions to include in the clojure-tools are
defined in the pom.xml as properties and make their way from there into all the
other files via several means.

## Package script

The script/package.sh script is used to build the tar file and clojure.rb file.

## Release Information

These files are not released into Maven central like other libraries. Instead, the tar
file is created and published to https://download.clojure.org.

The clojure.rb file is then manually updated in the brew central tap via PR.

## References

See the following resources for more information:

* https://clojure.org/guides/getting_started - installation
* https://clojure.org/guides/deps_and_cli - deps and CLI guide
* https://clojure.org/reference/deps_and_cli - deps and CLI reference
* https://github.com/clojure/tools.deps.alpha - dependency and classpath library

## Developer Information

* [GitHub project](https://github.com/clojure/brew-install)
* [How to contribute](https://dev.clojure.org/display/community/Contributing)
* [Bug Tracker](https://dev.clojure.org/jira/browse/TDEPS)

## License

Copyright © 2017 Rich Hickey, Alex Miller and contributors

Distributed under the Eclipse Public License 1.0, the same as Clojure.
