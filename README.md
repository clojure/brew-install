brew-install
=====================================

The brew-install project is used to create a brew formula for installation on
the Mac. The outputs of this project are a tar file (versioned) and a brew
formula (clojure.rb), suitable for updating in the brew central tap.

The tar file contains:

* brew-install jar - an uberjar including clojure-install and all its dep jars
* clj.props - the initial file of dep properties to install (Clojure, spec, tools.deps)
* install-clj script - just invokes the installer from clojure-install
* clj script - the main user-facing Clojure runner (pulled from tools.deps.alpha)

## Updating versions

The brew installer version is defined by the pom.xml project version. It should be updated
only by running script/build/update_version.

The Clojure, spec, and tools.deps.alpha versions to include in the brew installer are
defined in the pom.xml as properties files and make their way from there into all the
other files via several means.

## Package script

The script/package.sh script is used to build the tar file and clojure.rb file.

## Release Information

These files are not released into Maven central like other libraries. Instead, the tar
file is created and published TBD.

The clojure.rb file is then manually updated in the brew central tap via PR.

Release history:

* not yet released

## References

See the following resources for more information:

* https://github.com/clojure/tools.deps.alpha - library + clj script
* https://github.com/clojure/clojure-install - installer jar

## Developer Information

* [GitHub project](https://github.com/clojure/brew-install)
* [How to contribute](https://dev.clojure.org/display/community/Contributing)
* [Bug Tracker](https://dev.clojure.org/jira/browse/INST)

## License

Copyright © 2017 Rich Hickey, Alex Miller and contributors

Distributed under the Eclipse Public License, the same as Clojure.
