(ns clojure.run.test-exec
  (:require
    [clojure.test :refer :all]
    [clojure.string :as str]
    [clojure.run.exec :as exec]
    clojure.set)
  (:import
    [java.io File]
    [clojure.lang ExceptionInfo]))

(deftest test-read-args
  (is (= [] (#'exec/read-args [])))
  (is (= ['a [1 2] :k] (#'exec/read-args ["a" "[1 2]" ":k"])))

  ;; unreadable arg message contains the bad value
  (is (thrown-with-msg? ExceptionInfo #":::a" (#'exec/read-args [":::a"]))))

(deftest test-parse-fn
  (are [expected args] (= expected (#'exec/parse-fn args))
    nil []
    {:function '[foo/bar]} ['foo/bar]
    {:overrides [:x 1 :y 1]} [:x 1 :y 1]
    {:function '[foo]} ['foo]
    {:function '[foo] :overrides [:x 1 :y 1]} ['foo :x 1 :y 1]
    {:overrides [:x 1 :y 1]} [:x 1 :y 1]
    {:overrides [:a 1 :b 2], :trailing {:b 42}} [:a 1 :b 2 {:b 42}]
    {:function '[foo/bar], :trailing {:a 1}} ['foo/bar {:a 1}]
    {:overrides [:x 1 :k 1], :trailing {:a 1}} [:x 1 :k 1 {:a 1}]
    {:function '[foo/bar], :overrides [:x 1 :y 2], :trailing {:y 42}} ['foo/bar :x 1 :y 2 {:y 42}])

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
(defn flip [val] (reset! stash (clojure.set/map-invert val)))

(defn- encapsulate-main
  [basis args]
  (let [fake-basis (File/createTempFile "basis" nil)]
    (save nil)
    (.deleteOnExit fake-basis)
    (binding [*print-namespace-maps* false]
      (spit fake-basis (pr-str basis))
      (System/setProperty "clojure.basis" (.getAbsolutePath fake-basis)))
    (binding [exec/*exit* (constantly nil)]
      (apply exec/-main args))
    @stash))

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
  (are [stashed args basis] (= stashed (encapsulate-main basis args))
    ;; ad hoc, fully resolved, with both key and path vector
    {:a 1, :b {:c 2}} ["clojure.run.test-exec/save" ":a" "1" "[:b,:c]" "2"] {}

    ;; TODO: address when function comp is back
    ;;{1 :a, {:c 2} :b} ["clojure.run.test-exec/save" "clojure.run.test-exec/flip" ":a" "1" "[:b,:c]" "2"] {}

    ;; ad hoc, resolved by default-ns
    {:a 1} ["save" ":a" "1"] {:execute-args {:ns-default 'clojure.run.test-exec}}

    ;; ad hoc, resolved alias
    {:a 1} ["a/save" ":a" "1"] {:execute-args {:ns-aliases {'a 'clojure.run.test-exec}}}

    ;; exec-fn with overrides
    {:a 1, :b 2} [":b" "2"] {:execute-args {:exec-fn 'clojure.run.test-exec/save :exec-args {:a 1 :b 1}}}

    ;; exec-fn resolved by :ns-default, aliased exec-args
    {:a 1, :b 1} [] {:execute-args {:exec-fn 'save, :exec-args {:a 1, :b 1} :ns-default 'clojure.run.test-exec}})

  ;; missing override val: "Key is missing value: :foo\n"
  (is (str/includes? (with-err-str (encapsulate-main {} [":foo"])) ":foo"))

  ;; no function: "No function found on command line or in :exec-fn\n"
  (is (str/includes? (with-err-str (encapsulate-main {} [])) "No function"))

  ;; unqualified function: "Unqualified function can't be resolved: foo\n"
  (is (str/includes? (with-err-str (encapsulate-main {} ["foo"])) "foo"))
  )
