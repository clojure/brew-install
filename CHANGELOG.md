Changelog
===========

* 1.10.1.455 on June 28, 2019
  * Fix some manpage/help formatting
  * TDEPS-131 Fix bug tracker link in man page
  * Update to tools.deps 0.7.505
* 1.10.1.447 on June 6, 2019
  * Add new clj option to man page and clj help
* 1.10.1.445 on June 6, 2019
  * Change default Clojure to 1.10.1
* 1.10.0.442 on Mar 16, 2019
  * Update to tools.deps.alpha 0.6.496
  * Early release of Windows clj
* 1.10.0.414 on Feb 13, 2019
  * Update to tools.deps.alpha 0.6.488
* 1.10.0.411 on Jan 4, 2019
  * Update to tools.deps.alpha 0.6.480
* 1.10.0.408 on Jan 2, 2019 
  * Update to tools.deps.alpha 0.6.474
  * FIX TDEPS-82 - ensure -Sdescribe doesn't trigger resolution
* 1.10.0.403 on Dec 17, 2018
  * Changed default Clojure version to 1.10
* 1.9.0.397 on Oct 17, 2018
  * Update to tools.deps.alpha 0.5.460
* 1.9.0.394 on Sept 15, 2018
  * Update to tools.deps.alpha 0.5.452
* 1.9.0.391 on July 19, 2018
  * FIX TDEPS-77 - fix bad break character in rlwrap
  * FIX TDEPS-86 - use non-0 exit code in clj if rlwrap doesn't exist
  * FIX TDEPS-87 - change wording describing -Sdeps in help and man
* 1.9.0.381 on May 11, 2018
  * FIX TDEPS-76 - use exec for final Java invocation in script
  * NEW Convey lib map via Java system property
* 1.9.0.375 on Apr 14, 2018
  * FIX TDEPS-61 - switch to use Clojars CDN repo
  * FIX TDEPS-71 - better error if Java not installed
  * FIX TDEPS-65 - specify permissions on installed files
* 1.9.0.358 on Mar 2, 2018 
  * FIX linux-install - use mkdir -p to ensure parent dirs are created
  * FIX brew install - move man page installation from formula to install.sh
  * FIX TDEPS-45 - don't swipe -h flag if main aliases are in effect
  * FIX TDEPS-47 - use classpath cache with -Sdeps
* 1.9.0.348 on Feb 23, 2018
  * NEW Add --prefix to linux-install (INST-9)
  * NEW Add man page to installation (INST-18)
  * FIX Fix uberjar construction to avoid overlap of file and directory with same name
  * FIX Add missing license file
* 1.9.0.341 on Feb 21, 2018
  * CHANGE -Senv to -Sdescribe
* 1.9.0.338 on Feb 20, 2018
  * NEW -Senv - print edn for Clojure config, similar to -Sverbose info
  * NEW -Scp - provide a custom classpath and ignore classpath gen
* 1.9.0.326 on Feb 2, 2018
  * NEW -O - Java option aliases (append if multiple)
  * NEW -M - clojure.main option aliases (replace if multiple)
  * NEW -A - generic alias can combine any kind of alias and all are applied
  * FIX - if multiple alias switches supplied, they combine
  * FIX - whitespace in help fixed
* 1.9.0.315 on Jan 23, 2018
  * NEW -Stree to print dependency tree
  * NEW -Sdeps to supply a deps.edn on the command line as data
  * FIX bug with git deps using :deps/root writing File objects to libs files
* 1.9.0.309 on Jan 18, 2018
  * NEW -Spom emits dep exclusions and classifier
  * NEW pom file reader for local and git deps
  * FIX git deps now use :deps/root if specified
  * FIX major updates to improve transitive version selection
  * ENHANCE git version resolution uses stricter rules in comparison
  * ENHANCE dump stack on unexpected errors for debugging
* 1.9.0.302 on Jan 8, 2018
  * CHANGE git dep attributes (removed :rev, added :tag and :sha)
  * FIX Java 9 warning with -Spom
  * NEW -Sresolve-tags
* 1.9.0.297 on Jan 4, 2018
  * NEW git deps
  * NEW Updated -Spom to include repositories in the pom
* 1.9.0.273 on Dec 8, 2017
  * Initial release for 1.9
