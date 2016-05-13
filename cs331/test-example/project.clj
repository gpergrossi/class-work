(defproject test-example "1.0.0-"
  :description "CS 331 Programming Assignment &mdash; Test Example"
  :url "http://mccarthy.cs.iit.edu/cs331/assignments/test-example"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure "1.5.1"]]
  :profiles {:dev {:dependencies [[speclj "2.5.0"]]}}
  :plugins [[speclj "2.5.0"]]
  :test-paths ["spec/"])
