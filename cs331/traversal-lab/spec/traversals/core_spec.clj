(ns traversals.core-spec
  (:require [speclj.core :refer :all]
            [traversals.core :refer :all])
  (:import [traversals.core BNode])
  )

;; # The Tests
;;
;; We are going to use [spelj](https://github.com/slagyr/speclj) for our tests.


(describe "The spec file"
          (it "should have some tests."
              (should false)))

(run-specs)
