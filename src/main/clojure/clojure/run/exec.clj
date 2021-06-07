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
    [clojure.lang ExceptionInfo]))

(set! *warn-on-reflection* true)

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

(defn exec
  "Resolve and execute the function f (a symbol) with args"
  [f & args]
  (let [resolved-f (requiring-resolve' f)]
    (if resolved-f
      (apply resolved-f args)
      (throw (err "Function not found:" f)))))

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

(defn- combine-alias-data
  "Combine the data from multiple aliases, for a particular key, given a combining rule"
  [alias-data key rule]
  (->> alias-data (map key) (remove nil?) rule))

(defn- resolve-alias
  "Retrieve an alias's data in basis"
  [basis alias]
  (get-in basis [:aliases alias]))

(defn- read-basis
  []
  (when-let [f (jio/file (System/getProperty "clojure.basis"))]
    (if (and f (.exists f))
      (->> f slurp (edn/read-string {:default tagged-literal}))
      (throw (err "No basis declared in clojure.basis system property")))))

(defn- read-aliases
  "Given some aliases, look up the aliases in the basis, combine the data per key,
  specifically the keys :exec-fn, :exec-args, :ns-aliases, and :ns-default.
  If :exec-args is an alias, resolve it."
  [basis aliases]
  (let [alias-data (map #(resolve-alias basis %) aliases)
        exec-args (combine-alias-data alias-data :exec-args #(apply merge %))
        resolved-args (if (keyword? exec-args) (resolve-alias basis exec-args) exec-args)]
    (when (not (or (nil? resolved-args) (map? resolved-args)))
      (throw (err "Invalid :exec-args, must be map or alias keyword:" resolved-args)))
    {:exec-fn (combine-alias-data alias-data :exec-fn last)
     :exec-args resolved-args
     :ns-aliases (combine-alias-data alias-data :ns-aliases #(apply merge %))
     :ns-default (combine-alias-data alias-data :ns-default last)}))

(def arg-spec (s/cat :fns (s/* symbol?) :kvs (s/* (s/cat :k (s/nonconforming (s/or :keyword keyword? :path vector?)) :v any?)) :trailing (s/? map?)))

(defn- build-fn-descriptor [parsed {:keys [fns kvs trailing] :as extra}]
  (cond-> parsed
    fns (assoc :function fns)
    trailing (assoc :trailing trailing)
    kvs (assoc :overrides (reduce #(-> %1 (conj (:k %2)) (conj (:v %2))) [] kvs))))

(defn- build-error [expl]
  (let [err-str (with-out-str
                  (doseq [problem (:clojure.spec.alpha/problems expl)]
                    (println (:reason problem) (:clojure.spec.alpha/value expl))))]
    (err "Problem parsing arguments: " err-str)))

(defn- parse-fn
  [parsed args]
  (if (seq args)
    (let [conf (s/conform arg-spec args)]
      (if (s/invalid? conf)
        (let [expl (s/explain-data arg-spec args)]
          (throw (build-error expl)))
        (build-fn-descriptor parsed conf)))
    parsed))

(defn- parse-kws
  "Parses a concatenated string of keywords into a collection of keywords
  Ex: (parse-kws \":a:b:c\") ;; returns: (:a :b :c)"
  [s]
  (->> (str/split (or s "") #":")
    (remove str/blank?)
    (map
      #(if-let [i (str/index-of % \/)]
         (keyword (subs % 0 i) (subs % (inc i)))
         (keyword %)))))

(defn- parse-args
  [[a1 & as :as all]]
  (if (= a1 '--aliases)
    (parse-fn {:aliases (parse-kws (pr-str (first as)))} (rest as))
    (parse-fn nil all)))

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

(defn ^:dynamic *exit*
  [code]
  (System/exit code))

(defn -main
  [& args]
  (try
    (let [{:keys [function aliases overrides trailing]} (-> args read-args parse-args)
          {:keys [exec-fn exec-args ns-aliases ns-default]} (when aliases (read-aliases (read-basis) aliases))
          f (or function (if (symbol? exec-fn) [exec-fn] exec-fn))]
      (when (or (nil? f) (empty? f))
        (if (symbol? (first overrides))
          (throw (err "Key is missing value:" (last overrides)))
          (throw (err "No function found on command line or in :exec-fn"))))
      (loop [fns f, args (merge (apply-overrides exec-args overrides) trailing)]
        (if (seq fns)
          (recur (rest fns) (exec (qualify-fn (first fns) ns-aliases ns-default) args))
          args)))
    (catch ExceptionInfo e
      (if (-> e ex-data :exec-msg)
        (binding [*out* *err*]
          (println (.getMessage e))
          (*exit* 1))
        (throw e)))))

(comment
  (parse-args []) ;;=> nil
  (parse-args ['--aliases :a:b])                     ;;=> {:aliases (:a :b)}
  (parse-args ['--aliases :a:b 'foo/bar])            ;;=> {:aliases (:a :b), :function [foo/bar]}
  (parse-args ['--aliases :a:b 'foo/bar :x 1 :y 2])  ;;=> {:aliases (:a :b), :function [foo/bar], :overrides [:x 1 :y 2]}
  (parse-args ['--aliases :a:b 'foo/bar :x 1 :y])    ;;=> Except, missing value for :y
  (parse-args ['--aliases :a:b :x 1 :k 1])           ;;=> {:aliases (:a :b), :overrides [:x 1 :k 1]}
  (parse-args ['foo/bar])                            ;;=> {:function [foo/bar]}
  (parse-args ['foo/bar :x 1 :y])                    ;;=> Except, missing value for :y
  (parse-args [:x 1 :ZZZZZZZZZZZ])                   ;;=> Except, missing value for :ZZZZZZZZZZZ

  (parse-args [:a 1 :b 2])                           ;;=> {:overrides [:a 1 :b 2]}
  (parse-args [:a 1 :b 2 {:b 42}])                   ;;=> {:overrides [:a 1 :b 2], :trailing {:b 42}}
  (parse-args ['foo/bar {:a 1}])                     ;;=> {:function [foo/bar], :trailing {:a 1}}
  (parse-args ['--aliases :a:b :x 1 :k 1 {:a 1}])    ;;=> {:aliases (:a :b), :overrides [:x 1 :k 1], :trailing {:a 1}}
  (parse-args ['foo/bar :x 1 :y 2 {:y 42}])          ;;=> {:function [foo/bar], :overrides [:x 1 :y 2], :trailing {:y 42}}
  (parse-args ['foo/bar :x 1 :y {:y 42}])            ;;=> {:function [foo/bar], :overrides [:x 1 :y {:y 42}]}

  (-> ["clojure.run.test-exec/save" ":a" "1" "[:b,:c]" "2"]
      read-args
      parse-args)
  
  (s/conform arg-spec '[a b :a 1 :b 2 {}])
  (s/conform arg-spec '[a b])
  (s/conform arg-spec '[a])
  (s/conform arg-spec '[a {:a 1 :b 2}])
  (s/conform arg-spec '[:a 1 :b 2])
  (s/conform arg-spec '[foo/bar :x 1 :y])
  (s/conform arg-spec '[clojure.run.test-exec/save :a 1 [:b :c] 2])
  
  (read-aliases {:aliases {:a {:exec-fn 'clojure.core/pr :exec-args {:a 1}}}} [:a])
  (read-aliases {:aliases {:a {:exec-fn 'pr :exec-args {:a 1} :ns-default 'clojure.core}}} [:a])
  (read-aliases {:aliases {:a {:exec-fn 'core/pr :exec-args {:a 1} :ns-aliases {'core 'clojure.core}}}} [:a])

  (read-aliases nil [:a])
  )
