(ns clojure.run.test-exec
  (:require
    [clojure.edn :as edn]
    [clojure.test :refer :all]
    [clojure.string :as str]
    [clojure.run.exec :as exec]
    clojure.set)
  (:import
    [java.io File]
    [clojure.lang ExceptionInfo]))

(defn submap?
  "Is m1 a subset of m2?"
  [m1 m2]
  (if (and (map? m1) (map? m2))
    (every? (fn [[k v]] (and (contains? m2 k)
                             (submap? v (get m2 k))))
            m1)
    (= m1 m2)))

(deftest test-read-args
  (is (= [] (#'exec/read-args [])))
  (is (= ['a [1 2] :k] (#'exec/read-args ["a" "[1 2]" ":k"])))

  ;; unreadable arg message contains the bad value
  (is (thrown-with-msg? ExceptionInfo #":::a" (#'exec/read-args [":::a"]))))

(deftest test-parse-fn
  (are [expected args] (= expected (#'exec/parse-fn args))
    nil []
    {:function 'foo/bar} ['foo/bar]
    {:overrides [:x 1 :y 1]} [:x 1 :y 1]
    {:function 'foo} ['foo]
    {:function 'foo :overrides [:x 1 :y 1]} ['foo :x 1 :y 1]
    {:overrides [:x 1 :y 1]} [:x 1 :y 1]
    {:overrides [:a 1 :b 2], :trailing {:b 42}} [:a 1 :b 2 {:b 42}]
    {:function 'foo/bar, :trailing {:a 1}} ['foo/bar {:a 1}]
    {:overrides [:x 1 :k 1], :trailing {:a 1}} [:x 1 :k 1 {:a 1}]
    {:function 'foo/bar, :overrides [:x 1 :y 2], :trailing {:y 42}} ['foo/bar :x 1 :y 2 {:y 42}])

  ;; missing last override value prints value missing for key (like hash-map)
  (is (thrown-with-msg? ExceptionInfo #":y" (#'exec/parse-fn [:x 1 :y])))
  )

(deftest test-qualify-fn
  (are [expected sym aliases default]
    (= expected (#'exec/qualify-fn sym aliases default))
    'a/b 'a/b nil nil
    'a/b 'b nil 'a
    'a/b 'my-alias/b {'my-alias 'a} nil)

  ;; function is not a symbol
  (is (thrown-with-msg? ExceptionInfo #"100" (#'exec/qualify-fn 100 nil nil)))

  ;; unqualified, no default-ns
  (is (thrown-with-msg? ExceptionInfo #"my-sym" (#'exec/qualify-fn 'my-sym nil nil))))

(def stash (atom nil))
(defn save [val] (reset! stash val))

(defn- encapsulate-main-with-effect
  [exec-args args]
  (let [fake-basis (File/createTempFile "basis" nil)]
    (save nil)
    (.deleteOnExit fake-basis)
    (binding [*print-namespace-maps* false]
      (spit fake-basis (pr-str {:argmap exec-args}))
      (System/setProperty "clojure.basis" (.getAbsolutePath fake-basis)))
    (binding [exec/*exit* (constantly nil)]
      (apply exec/-main args))
    @stash))

(defn puppet [{:keys [ret err print-val print-val-err]}]
  (when print-val
    (print print-val)
    (flush))
  (when print-val-err
    (binding [*out* *err*]
      (print print-val-err)
      (flush)))
  (if err
    (throw (RuntimeException. err))
    ret))

(defn- encapsulate-invoke
  [exec-args args]
  (let [fake-basis (File/createTempFile "basis" nil)]
    (.deleteOnExit fake-basis)
    (binding [*print-namespace-maps* false]
      (spit fake-basis (pr-str {:argmap exec-args}))
      (System/setProperty "clojure.basis" (.getAbsolutePath fake-basis)))
    (binding [exec/*exit* (constantly nil)]
      (edn/read-string
       (with-out-str
         (apply exec/-main args))))))

(defmacro with-err-str
  "Evaluates exprs in a context in which *err* is bound to a fresh
  StringWriter.  Returns the string created by any nested printing
  calls."
  {:added "1.0"}
  [& body]
  `(let [s# (new java.io.StringWriter)]
     (binding [*err* s#]
       ~@body
       (str s#))))

(deftest test-main
  (are [stashed args exec-args] (= stashed (encapsulate-main-with-effect exec-args args))
    ;; ad hoc, fully resolved, with both key and path vector
    {:a 1, :b {:c 2}} ["clojure.run.test-exec/save" ":a" "1" "[:b,:c]" "2"] {}

    ;; ad hoc, resolved by default-ns
    {:a 1} ["save" ":a" "1"] {:ns-default 'clojure.run.test-exec}

    ;; ad hoc, resolved alias
    {:a 1} ["a/save" ":a" "1"] {:ns-aliases {'a 'clojure.run.test-exec}}

    ;; exec-fn with overrides
    {:a 1, :b 2} [":b" "2"] {:exec-fn 'clojure.run.test-exec/save :exec-args {:a 1 :b 1}}

    ;; exec-fn resolved by :ns-default, aliased exec-args
    {:a 1, :b 1} [] {:exec-fn 'save, :exec-args {:a 1, :b 1} :ns-default 'clojure.run.test-exec})

  (are [return args exec-args] (submap? return (encapsulate-invoke exec-args (map pr-str args)))
    ;; non-map return, note that val is stringified!
    {:tag :ret, :val "42"}
    ['clojure.run.test-exec/puppet {:clojure.exec/invoke :fn, :ret 42}] {}

    ;;  map return
    {:tag :ret, :val "{:a \"1\"}"}
    ['clojure.run.test-exec/puppet {:clojure.exec/invoke :fn, :ret {:a "1"}}] {}

    ;; capture out
    {:tag :ret :val "42" :out "hi there"}
    ['clojure.run.test-exec/puppet {:clojure.exec/invoke :fn, :ret 42, :print-val "hi there", :clojure.exec/out :capture}] {}

    ;; capture err
    {:tag :ret :val "42" :err "hi there"}
    ['clojure.run.test-exec/puppet {:clojure.exec/invoke :fn, :ret 42, :print-val-err "hi there", :clojure.exec/err :capture}] {})

  (let [res (encapsulate-invoke {} (map pr-str ['clojure.run.test-exec/puppet {:clojure.exec/invoke :fn, :err "msg"}]))]
    (is (= :err (:tag res)))
    (is (str/starts-with? (:val res) "{:via [{:type java.lang.RuntimeException, :message \"msg\"")))

  ;; missing override val: "Key is missing value: :foo\n"
  (is (str/includes? (with-err-str (encapsulate-main-with-effect {} [":foo"])) ":foo"))

  ;; no function: "No function found on command line or in :exec-fn\n"
  (is (str/includes? (with-err-str (encapsulate-main-with-effect {} [])) "No function"))

  ;; unqualified function: "Unqualified function can't be resolved: foo\n"
  (is (str/includes? (with-err-str (encapsulate-main-with-effect {} ["foo"])) "foo"))
  )

(comment
  (test-main)

  )