brew-install
=====================================

The brew-install project is used to create a brew formula for installing
clojure tools on the Mac. The outputs of this project are a tar file
(versioned) and a brew formula (clojure.rb), suitable for updating in the 
brew central tap.

The tar file contains:

* clojure-tools jar - an uberjar for constructing classpaths via tools.deps
* deps.edn - a copy of the root deps.edn file (no longer used at runtime)
* example-deps.edn - the initial user deps.edn file
* tools.edn - the tools.tools tool to auto install
* clojure script - the main Clojure runner
* clj script - a clojure wrapper for interactive repl use (adds rlwrap)

## Updating versions

The clojure-tools version is defined by the pom.xml project version. It 
should be updated only by running script/update_version (the build does
this automatically). The current version is stored in the VERSION file.

The Clojure and tools.deps versions to include in the clojure-tools are
taken from the deps.edn.

## Package script

To create the packages and installers, run:

```
clojure -T:build release
```

## Release Information

These files are not released into Maven central like other libraries. Instead, the tar
file is created and published to https://download.clojure.org.

The [Clojure homebrew tap](https://github.com/clojure/homebrew-tools) is updated when new releases
are created or promoted to stable.

The Homebrew Central Clojure recipe is updated manually so may lag the Clojure tap.

## References

See the following resources for more information:

* https://clojure.org/guides/getting_started - installation
* https://clojure.org/guides/deps_and_cli - deps and CLI guide
* https://clojure.org/reference/deps_and_cli - deps and CLI reference
* https://github.com/clojure/tools.deps - dependency and classpath library

## Developer Information

* [GitHub project](https://github.com/clojure/brew-install)
* [How to contribute](https://clojure.org/community/contributing)
* [Bug Tracker](https://clojure.atlassian.net/browse/TDEPS)

## License

Copyright © Rich Hickey, Alex Miller and contributors

Distributed under the Eclipse Public License 1.0, the same as Clojure.
