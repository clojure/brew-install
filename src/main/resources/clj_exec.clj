;   Copyright (c) Rich Hickey. All rights reserved.
;   The use and distribution terms for this software are covered by the
;   Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php)
;   which can be found in the file epl-v10.html at the root of this distribution.
;   By using this software in any fashion, you are agreeing to be bound by
;   the terms of this license.
;   You must not remove this notice, or any other, from this software.

(ns clj-exec
  (:require
    ;; NOTE: ONLY depend on Clojure core, loaded in user's classpath so can't have any deps
    [clojure.edn :as edn]
    [clojure.java.io :as jio]
    [clojure.string :as str])
  (:import
    [clojure.lang ExceptionInfo]))

(defn- err
  [& msg]
  (throw (ex-info (str/join " " msg) {:exec-msg true})))

(defn- read-basis
  []
  (when-let [f (jio/file (System/getProperty "clojure.basis"))]
    (if (and f (.exists f))
      (-> f slurp edn/read-string)
      (throw (err "No basis declared in clojure.basis system property")))))

(defn- check-first
  [arg]
  (cond
    (nil? arg) (throw (err "No args passed to exec"))
    (= "-X" arg) (throw (err "No alias specified with -X"))
    (= "-F" arg) (throw (err "No function specified with -F"))
    (str/starts-with? arg "-X") (let [alias (edn/read-string (subs arg 2))]
                                  (if (keyword? alias)
                                    {:alias alias}
                                    (throw (err (str "Invalid first arg to exec: " arg)))))
    (str/starts-with? arg "-F") (let [fsym (edn/read-string (subs arg 2))]
                                  (if (qualified-symbol? fsym)
                                    {:fn fsym}
                                    (throw (err (str "Invalid first arg to exec: " arg)))))
    :else (throw (err (str "Invalid first arg to exec: " arg)))))

(defn- parse-args
  [[arg & args]]
  (let [fread (check-first arg)
        arg-count (count args)]
    (when (odd? (count args))
      (throw (err (str "Key is missing value: " (last args)))))
    (cond-> fread
      (seq args) (assoc :overrides (mapv edn/read-string args)))))

(defn- requiring-resolve'
  ;; copied and modified from core to remove constraints on Clojure 1.10.x
  [sym]
  (if (nil? (namespace sym))
    (throw (err (str "Not a qualified symbol: " sym)))
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
      (throw (err (str "Function not found: " f))))))

(defn- apply-overrides
  [args overrides]
  (reduce (fn [m [k v]]
            (if (sequential? k)
              (assoc-in m k v)
              (assoc m k v)))
    args (partition-all 2 overrides)))

(defn- exec-alias
  [alias overrides]
  (let [basis (read-basis)
        {f :fn, maybe-args :args} (get-in basis [:aliases alias])
        args (cond
               (nil? maybe-args) nil
               (map? maybe-args) maybe-args
               (keyword? maybe-args) (get-in basis [:aliases maybe-args])
               :else (throw (err (str "Invalid :args for exec, must be map or alias keyword: " (pr-str maybe-args)))))]
    (exec f (apply-overrides args overrides))))

(defn- exec-fn
  [f overrides]
  (exec f (when (seq overrides) (apply-overrides nil overrides))))

(defn -main
  [& args]
  (try
    (let [{:keys [alias overrides] :as parsed} (parse-args args)]
      (if alias
        (exec-alias alias overrides)
        (exec-fn (:fn parsed) overrides)))
    (catch ExceptionInfo e
      (if (-> e ex-data :exec-msg)
        (binding [*out* *err*]
          (println (.getMessage e)))
        (throw e)))))