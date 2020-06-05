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
      {:tasks '[[clean] [sync-pom] [compile-clj] [copy] [jar] [uber]]
       :params (merge
                 '{:build/target-dir "target"
                   :build/class-dir "classes"
                   :build/src-pom "pom.xml"
                   :build/ns-compile [clojure.tools.deps.alpha
                                      clojure.tools.build.tasks]
                   :build/compiler-opts {:elide-meta [:doc :file :line]
                                         :direct-linking true}
                   :build/copy-to "resources"
                   :build/copy-specs [{:from "src/main/resources"
                                       :replace {"${project.version}" :build/version
                                                 "${version.short}" :clj/version-short
                                                 "${stable.version}" :clj/stable-version
                                                 "${stable.sha}" :clj/stable-sha
                                                 "${clojure.version}" :clj/clojure-version
                                                 "${tools.deps.version}" :clj/tdeps-version}}]
                   :build/lib org.clojure/clojure-tools}
                 params)})))
