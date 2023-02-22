;   Copyright (c) Rich Hickey. All rights reserved.
;   The use and distribution terms for this software are covered by the
;   Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php)
;   which can be found in the file epl-v10.html at the root of this distribution.
;   By using this software in any fashion, you are agreeing to be bound by
;   the terms of this license.
;   You must not remove this notice, or any other, from this software.

(ns clojure.run.exec
  (:require
    ;; NOTE: ONLY depend on Clojure core, loaded in user's classpath so can't have any deps
    [clojure.edn :as edn]
    [clojure.java.io :as jio]
    [clojure.string :as str]
    [clojure.spec.alpha :as s])
  (:import
    [clojure.lang ExceptionInfo]
    [java.io StringWriter Writer FileNotFoundException]
    [java.util.concurrent Executors ThreadFactory]))

(set! *warn-on-reflection* true)
(def ^:dynamic *ns-default* nil)
(def ^:dynamic *ns-aliases* nil)

(defn- err
  ^Throwable [& msg]
  (ex-info (str/join " " msg) {:exec-msg true}))

(defn- requiring-resolve'
  ;; copied and modified from core to remove constraints on Clojure 1.10.x
  [sym]
  (if (nil? (namespace sym))
    (throw (err "Not a qualified symbol:" sym))
    (or (resolve sym)
      (do
        (-> sym namespace symbol require)
        (resolve sym)))))

(defn remove-ns-keys
  "Remove keys in m with namespace string ns-str"
  [m ns-str]
  (reduce-kv #(if (= ns-str (namespace %2)) %1 (assoc %1 %2 %3)) {} m))

(defn- add-stream
  [envelope stream-tag ^Writer writer]
  (.flush writer)
  (let [s (str writer)]
    (if (str/blank? s)
      envelope
      (assoc envelope stream-tag s))))

(defn- envelope
  [args tag val out-wr err-wr start]
  (let [end (System/currentTimeMillis)]
    (cond-> {:tag tag
             :val (binding [*print-namespace-maps* false] (pr-str val))
             :ms (- end start)}
      (= :capture (:clojure.exec/out args)) (add-stream :out out-wr)
      (= :capture (:clojure.exec/err args)) (add-stream :err err-wr))))

(defn apply-program
  [f args]
  (let [clean-args (remove-ns-keys args "clojure.exec")
        out-wr (StringWriter.)
        err-wr (StringWriter.)
        start (System/currentTimeMillis)
        envelope (binding [*out* out-wr, *err* err-wr]
                   (try
                     (envelope args :ret (f clean-args) out-wr err-wr start)
                     (catch Throwable t
                       (envelope args :err (Throwable->map t) out-wr err-wr start))
                     (finally
                       (.close out-wr)
                       (.close err-wr))))]
    (binding [*print-namespace-maps* false]
      (prn envelope))))

(defn exec
  "Resolve and execute the function f (a symbol) with args"
  [f args]
  (try
    (let [resolved-f (try
                       (requiring-resolve' f)
                       (catch FileNotFoundException _
                         (throw (err "Namespace could not be loaded:" (namespace f)))))]
      (if resolved-f
        (if (= :fn (:clojure.exec/invoke args))
          (apply-program resolved-f args)
          (resolved-f args))
        (throw (err "Namespace" (namespace f) "loaded but function not found:" (name f)))))))

(defn- apply-overrides
  [args overrides]
  (reduce (fn [m [k v]]
            (if (sequential? k)
              (assoc-in m k v)
              (assoc m k v)))
    args (partition-all 2 overrides)))

(defn- qualify-fn
  "Compute function symbol based on exec-fn, ns-aliases, and ns-default"
  [fsym ns-aliases ns-default]
  ;; validation - make specs?
  (when (and fsym (not (symbol? fsym)))
    (throw (err "Expected function symbol:" fsym)))

  (when fsym
    (if (qualified-ident? fsym)
      (let [nsym (get ns-aliases (symbol (namespace fsym)))]
        (if nsym
          (symbol (str nsym) (name fsym))
          fsym))
      (if ns-default
        (symbol (str ns-default) (str fsym))
        (throw (err "Unqualified function can't be resolved:" fsym))))))

(defn- read-basis
 []
 (when-let [f (jio/file (System/getProperty "clojure.basis"))]
   (if (and f (.exists f))
     (->> f slurp (edn/read-string {:default tagged-literal}))
     (throw (err "No basis declared in clojure.basis system property")))))

(def arg-spec (s/cat :fns (s/? symbol?) :kvs (s/* (s/cat :k (s/nonconforming (s/or :keyword any? :path vector?)) :v any?)) :trailing (s/? map?)))

(defn- build-fn-descriptor [{:keys [fns kvs trailing] :as extra}]
  (cond-> {}
    fns (assoc :function fns)
    trailing (assoc :trailing trailing)
    kvs (assoc :overrides (reduce #(-> %1 (conj (:k %2)) (conj (:v %2))) [] kvs))))

(defn- build-error [expl]
  (let [err-str (with-out-str
                  (doseq [problem (:clojure.spec.alpha/problems expl)]
                    (println (:reason problem) (:clojure.spec.alpha/value expl))))]
    (err "Problem parsing arguments: " err-str)))

(defn- parse-fn
  [args]
  (when (seq args)
    (let [conf (s/conform arg-spec args)]
      (if (s/invalid? conf)
        (let [expl (s/explain-data arg-spec args)]
          (throw (build-error expl)))
        (build-fn-descriptor conf)))))

(defn- read-args
  [args]
  (loop [[a & as] args
         read-args []]
    (if a
      (let [r (try
                (edn/read-string {:default tagged-literal} a)
                (catch Throwable _
                  (throw (err "Unreadable arg:" (pr-str a)))))]
        (recur as (conj read-args r)))
      read-args)))

(defn- set-daemon-agent-executor
  "Set Clojure's send-off agent executor (also affects futures). This is almost
  an exact rewrite of the Clojure's executor, but the Threads are created as
  daemons."
  []
  (let [thread-counter (atom 0)
        thread-factory (reify ThreadFactory
                         (newThread [_ runnable]
                           (doto (Thread. runnable)
                             (.setDaemon true) ;; DIFFERENT
                             (.setName (format "CLI-agent-send-off-pool-%d"
                                         (first (swap-vals! thread-counter inc)))))))
        executor (Executors/newCachedThreadPool thread-factory)]
    (set-agent-send-off-executor! executor)))

(defn ^:dynamic *exit*
  ;; normal exit
  ([])
  ;; abnormal exit
  ([^Throwable t] (System/exit 1)))

(defn -main
  "Execute a function with map kvs.

  The classpath is determined by the clojure script and make-classpath programs
  and has already been set. Any execute argmap keys indicated via aliases will
  be read from the basis file :argmap passed via -Dclojure.basis. The exec args
  have the following possible keys:
    :exec-fn - symbol to be resolved in terms of the namespace context, will
               be overridden if passed as arg
    :exec-args - map of kv args
    :ns-default - namespace default for resolving functions
    :ns-aliases - map of alias symbol to namespace symbol for resolving functions

  The actual args to exec are essentially same as to -X:
    [fn] (kpath v)+ map?

  fn is resolved from either :exec-fn or fn
  map to pass to fn is built from merge of:
    exec-args map
    map built from kpath/v's
    trailing map"
  [& args]
  (try
    (let [execute-args (:argmap (read-basis))
          {:keys [function overrides trailing]} (-> args read-args parse-fn)
          {:keys [exec-fn exec-args ns-aliases ns-default]} execute-args
          f (or function exec-fn)]
      (when (nil? f)
        (if (symbol? (first overrides))
          (throw (err "Key is missing value:" (last overrides)))
          (throw (err "No function found on command line or in :exec-fn"))))
      (set-daemon-agent-executor)
      (binding [*ns-default* ns-default
                *ns-aliases* ns-aliases]
        (let [qualified-fn (qualify-fn f ns-aliases ns-default)
              args (merge (apply-overrides exec-args overrides) trailing)]
          (exec qualified-fn args)))
      (*exit*))
    (catch ExceptionInfo e
      (if (-> e ex-data :exec-msg)
        (binding [*out* *err*]
          (println (.getMessage e))
          (*exit* e))
        (throw e)))))

(comment
  (parse-fn []) ;;=> nil
  (parse-fn [:a:b 'foo/bar])            ;;=> {:function [foo/bar]}
  (parse-fn [:a:b 'foo/bar :x 1 :y 2])  ;;=> {:function [foo/bar], :overrides [:x 1 :y 2]}
  (parse-fn [:a:b 'foo/bar :x 1 :y])    ;;=> Except, missing value for :y
  (parse-fn [:x 1 :k 1])           ;;=> {:overrides [:x 1 :k 1]}
  (parse-fn ['foo/bar])                            ;;=> {:function [foo/bar]}
  (parse-fn ['foo/bar :x 1 :y])                    ;;=> Except, missing value for :y
  (parse-fn [:x 1 :ZZZZZZZZZZZ])                   ;;=> Except, missing value for :ZZZZZZZZZZZ

  (parse-fn [:a 1 :b 2])                           ;;=> {:overrides [:a 1 :b 2]}
  (parse-fn [:a 1 :b 2 {:b 42}])                   ;;=> {:overrides [:a 1 :b 2], :trailing {:b 42}}
  (parse-fn ['foo/bar {:a 1}])                     ;;=> {:function [foo/bar], :trailing {:a 1}}
  (parse-fn [:x 1 :k 1 {:a 1}])    ;;=> {:overrides [:x 1 :k 1], :trailing {:a 1}}
  (parse-fn ['foo/bar :x 1 :y 2 {:y 42}])          ;;=> {:function [foo/bar], :overrides [:x 1 :y 2], :trailing {:y 42}}
  (parse-fn ['foo/bar :x 1 :y {:y 42}])            ;;=> {:function [foo/bar], :overrides [:x 1 :y {:y 42}]}

  (-> ["clojure.run.test-exec/save" ":a" "1" "[:b,:c]" "2"]
      read-args
      parse-fn)

  (s/conform arg-spec '[a b :a 1 :b 2 {}])
  (s/conform arg-spec '[a b])
  (s/conform arg-spec '[a])
  (s/conform arg-spec '[a {:a 1 :b 2}])
  (s/conform arg-spec '[:a 1 :b 2])
  (s/conform arg-spec '[foo/bar :x 1 :y])
  (s/conform arg-spec '[clojure.run.test-exec/save :a 1 [:b :c] 2]))

