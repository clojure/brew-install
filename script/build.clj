(ns build
  (:require
    [clojure.tools.build :as build]))

(defn -main
  "Args - alternating key/value pairs. Should set:
    :build/version
    :clj/version-short
    :clj/stable-sha
    :clj/stable-version
    :clj/clojure-version
    :clj/tdeps-version"
  [& args]
  (let [vals (map #(if (= ":" (subs % 0 1)) (keyword (subs % 1)) %) args)
        params (apply hash-map vals)]
    (build/build
      {:tasks '[[dirs] [clean] [sync-pom] [compile-clj] [copy] [jar] [uber]]
       :params (merge
                 '{:build/ns-compile [clojure.tools.build
                                      clojure.tools.build.tasks.clean
                                      clojure.tools.build.tasks.compile-clj
                                      clojure.tools.build.tasks.copy
                                      clojure.tools.build.tasks.dirs
                                      clojure.tools.build.tasks.format-str
                                      clojure.tools.build.tasks.install
                                      clojure.tools.build.tasks.jar
                                      clojure.tools.build.tasks.javac
                                      clojure.tools.build.tasks.pom
                                      clojure.tools.build.tasks.process
                                      clojure.tools.build.tasks.sync-pom
                                      clojure.tools.build.tasks.uber
                                      clojure.tools.build.tasks.zip]
                   :build/compiler-opts {:elide-meta [:doc :file :line]
                                         :direct-linking true}
                   :build/copy-to "target/resources"
                   :build/copy-specs [{:from "src/main/resources"
                                       :replace {"${project.version}" :build/version
                                                 "${version.short}" :clj/version-short
                                                 "${stable.version}" :clj/stable-version
                                                 "${stable.sha}" :clj/stable-sha
                                                 "${clojure.version}" :clj/clojure-version
                                                 "${tools.deps.version}" :clj/tdeps-version}}]
                   :build/lib org.clojure/clojure-tools}
                 params)})))
