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
(def uber-file (format "target/clojure-tools-%s.jar" version))
(def tar-file (format "target/clojure-tools-%s.tar.gz" version))
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
                         "${tools.deps.version}" (get-in basis [:libs 'org.clojure/tools.deps :mvn/version])
                         "${stable.version}" (first stable)
                         "${stable.sha}" (second stable)}})

  ;; Make the uber jar
  (b/compile-clj {:basis basis :class-dir class-dir :src-dirs []
                  :compile-opts {:elide-meta [:doc :file :line] :direct-linking true}
                  :ns-compile '[clojure.tools.deps.script.make-classpath2
                                clojure.tools.deps.script.generate-manifest2
                                clojure.tools.deps.util.s3-aws-client]})
  (b/uber {:basis basis :class-dir class-dir :uber-file uber-file})

  ;; Make the exec jar
  (b/copy-dir {:src-dirs ["src/main/clojure"] :target-dir exec-dir})
  (b/jar {:class-dir exec-dir :jar-file exec-file})

  ;; Collect the tar file contents and make the tar and installer
  (doseq [f ["clojure" "clj" "install.sh" "linux-install.sh" "posix-install.sh"]]
    (b/process {:command-args ["chmod" "+x" (str filtered-dir "/clojure/install/" f)]}))
  (doseq [f ["clj" "clojure" "install.sh" "deps.edn" "example-deps.edn" "tools.edn"]]
    (b/copy-file {:src (str filtered-dir "/clojure/install/" f) :target (str tar-dir "/" f)}))
  (b/copy-file {:src (str doc-dir "/clojure.1") :target (str tar-dir "/clojure.1")})
  (b/copy-file {:src (str doc-dir "/clojure.1") :target (str tar-dir "/clj.1")})
  (b/copy-dir {:src-dirs [target-dir] :target-dir tar-dir :include "*.jar"})
  (b/process {:command-args ["tar" "-cvzf" tar-file "-Ctarget" "clojure-tools"]})

  ;; Embed artifact checksums within installers
  (let [sha (-> (:out (b/process {:command-args ["shasum" "-a" "256" tar-file] :out :capture})) (subs 0 64))]
    (doseq [[src target] [["clojure/install/clojure.rb"]
                          ["clojure/install/clojure@version.rb" (format "clojure@%s.rb" version)]
                          ["clojure/install/linux-install.sh"]
                          ["clojure/install/posix-install.sh"]]
            :let [target (str target-dir "/" (or target (peek (str/split src #"/"))))
                  src (str filtered-dir "/" src)]]
      (b/write-file {:path target
                     :string (str/replace (slurp src) "SHA" sha)}))))
