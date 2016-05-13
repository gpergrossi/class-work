(ns linked_lists.core-spec
  (:require [speclj.core :refer :all]
            [linked_lists.core :refer :all])
  (:import [linked_lists.core Cons]))

;; # The Tests
;;
;; We are going to use [spelj](https://github.com/slagyr/speclj) for our tests.


(describe "The record declaration"

          (it "should create something"
              (should (Cons. 10 20)))

          (it "should have a car"
              (should= (:car (Cons. 10 20)) 10))

          (it "should have a cdr"
              (should= (:cdr (Cons. 10 20)) 20))

          (it "should be chainable"
              (should= (-> (Cons. 10 (Cons. 20 (Cons. 30 40))) :cdr :cdr :cdr) 40)))

(describe "insert-at-beginning"
          (it "creates a cons cell"
              (should-not= nil (insert-at-beginning 10 nil)))

          (it "should work with empty lists"
              (should= (Cons. 10 nil) (insert-at-beginning 10 nil) ))
          
          (it "should work with lists that have data"
              (let [xx (Cons. 10 (Cons. 20 (Cons. 30 nil)))]
                (should= (Cons. 5 xx) (insert-at-beginning 5 xx) ))))

(run-specs)
