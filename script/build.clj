(ns build
  (:require
    [clojure.string :as str]
    [clojure.tools.build.api :as b]))

;; project config
(def lib 'org.clojure/clojure-tools)
(def version (str/trim (slurp "VERSION")))
(def basis (b/create-basis {}))
(def clojure-ver (get-in basis [:libs 'org.clojure/clojure :mvn/version]))
(def stable (str/split (str/trim (slurp "stable.properties")) #" "))

;; dirs
(def doc-dir "doc")
(def target-dir "target")
(def filtered-dir "target/filtered")
(def class-dir "target/classes")
(def exec-dir "target/exec")
(def tar-dir "target/clojure-tools")
(def zip-dir "target/win")
(def uber-file (format "target/clojure-tools-%s.jar" version))
(def tar-file (format "target/clojure-tools-%s.tar.gz" version))
(def zip-file "target/clojure-tools.zip")
(def exec-file "target/exec.jar")

(defn clean
  [_]
  (b/delete {:path "target"}))

(defn release
  [_]
  (clean nil)

  ;; Filter all resources, replacing properties as needed
  (b/copy-dir {:src-dirs ["src/main/resources"]
               :target-dir filtered-dir
               :replace {"${project.version}" version
                         "${version.short}" (str/replace version "." "")
                         "${clojure.version}" clojure-ver
                         "${tools.deps.version}" (get-in basis [:libs 'org.clojure/tools.deps.alpha :mvn/version])
                         "${stable.version}" (first stable)
                         "${stable.sha}" (second stable)}})

  ;; Make the uber jar
  (b/compile-clj {:basis basis :class-dir class-dir :src-dirs []
                  :compile-opts {:elide-meta [:doc :file :line] :direct-linking true}
                  :ns-compile '[clojure.tools.deps.alpha.script.make-classpath2
                                clojure.tools.deps.alpha.script.generate-manifest2]})
  (b/uber {:basis basis :class-dir class-dir :uber-file uber-file})

  ;; Make the exec jar
  (b/copy-dir {:src-dirs ["src/main/clojure"] :target-dir exec-dir})
  (b/compile-clj {:basis (b/create-basis {:user nil
                                          :project {:paths ["src/main/clojure"]
                                                    :deps {'org.clojure/clojure {:mvn/version clojure-ver}}}})
                  :class-dir exec-dir :src-dirs []
                  :compile-opts {:elide-meta [:doc :file :line] :direct-linking true}
                  :ns-compile '[clojure.run.exec]})
  (b/jar {:class-dir exec-dir :jar-file exec-file})

  ;; Collect the tar file contents and make the tar and installer
  (doseq [f ["clojure" "clj" "install.sh" "linux-install.sh"]]
    (b/process {:command-args ["chmod" "+x" (str filtered-dir "/clojure/install/" f)]}))
  (doseq [f ["clj" "clojure" "install.sh" "deps.edn" "example-deps.edn" "tools.edn"]]
    (b/copy-file {:src (str filtered-dir "/clojure/install/" f) :target (str tar-dir "/" f)}))
  (b/copy-file {:src (str doc-dir "/clojure.1") :target (str tar-dir "/clojure.1")})
  (b/copy-file {:src (str doc-dir "/clojure.1") :target (str tar-dir "/clj.1")})
  (b/copy-dir {:src-dirs [target-dir] :target-dir tar-dir :include "*.jar"})
  (b/process {:command-args ["tar" "-cvzf" tar-file "-Ctarget" "clojure-tools"]})
  (b/copy-file {:src (str filtered-dir "/clojure/install/linux-install.sh") :target (str target-dir "/linux-install.sh")})

  ;; Collect the windows files and make the windows zip file and installer
  (doseq [f ["ClojureTools.psd1" "ClojureTools.psm1" "deps.edn" "example-deps.edn" "tools.edn"]]
    (b/copy-file {:src (str filtered-dir "/clojure/install/" f) :target (str zip-dir "/ClojureTools/" f)}))
  (b/copy-dir {:src-dirs [target-dir] :target-dir (str zip-dir "/ClojureTools") :include "*.jar"})
  (b/zip {:src-dirs [zip-dir] :zip-file zip-file})
  (b/copy-file {:src (str filtered-dir "/clojure/install/win-install.ps1") :target (str target-dir "/win-install.ps1")})

  ;; Prep the brew files
  (let [sha (-> (:out (b/process {:command-args ["shasum" "-a" "256" tar-file] :out :capture})) (subs 0 64))
        brew-recipe (slurp (str filtered-dir "/clojure/install/clojure.rb"))
        version-recipe (slurp (str filtered-dir "/clojure/install/clojure@version.rb"))]
    (b/write-file {:path "target/clojure.rb" :string (str/replace brew-recipe "SHA" sha)})
    (b/write-file {:path (format "target/clojure@%s.rb" version) :string (str/replace version-recipe "SHA" sha)})))
