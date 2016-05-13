(ns dlist-atom.core-spec
;  (:refer-clojure :exclude [])
  (:require [speclj.core :refer :all]
            [dlist-atom.core :refer :all])
;  (:import [dlist-atom.core ])
  )

;; # The Tests
;;
;; We are going to use [spelj](https://github.com/slagyr/speclj) for our tests.

(describe "dnode"
  (it "should create something"
    (should (dnode 5)))
  (it "should copy value"
    (should= (d-data (dnode 5)) 5)))

(describe "dlist"
  (it "should be amazing"
    (should (dlist)))
  (it "should have proper initial values"
    (should= (d-size (dlist)) 0)))

(describe "insert-front"
  (it "should increase the size of the list"
    (let [test1 (dlist)]
      (insert-front test1 1)
      (should= 1 (d-size test1))))
  (it "should make the first element n"
    (let [test1 (list-to-dlist '(5 9 31))]
      (insert-front test1 1337)
      (should= '(1337 5 9 31) (show-dlist test1)))))

(describe "insert-last"
  (it "should increase the size of the list"
    (let [test1 (dlist)]
      (insert-last test1 1)
      (should= 1 (d-size test1))))
  (it "should make the last element n"
    (let [test1 (list-to-dlist '(5 9 31))]
      (insert-last test1 1337)
      (should= '(5 9 31 1337) (show-dlist test1)))))

(describe "insert-sorted"
  (it "should increase the size of the list"
    (let [test1 (dlist)]
      (insert-last test1 1)
      (should= 1 (d-size test1))))
  (it "should maintain sorting"
    (let [test1 (list-to-dlist '(1 2 4 8 16))]
      (insert-sorted test1 12)
      (should= '(1 2 4 8 12 16) (show-dlist test1))
      (insert-sorted test1 6)
      (should= '(1 2 4 6 8 12 16) (show-dlist test1))
      (should= '(16 12 8 6 4 2 1) (show-dlist-reverse test1)))))

(describe "index-forward"
  (it "should return nil when it can't find the element"
    (should= nil (index-forward (dlist) 'not_in_there)))
  (it "should return an expected result"
    (let [test1 (dlist)]
      (insert-front test1 2)
      (insert-front test1 1)
      (should= 1 (index-forward test1 2)))))

(describe "index-backward"
  (it "should return nil when it can't find the element"
    (should= nil (index-backward (dlist) 'not_in_there)))
  (it "should return an expected result"
    (let [test1 (dlist)]
      (insert-front test1 2)
      (insert-front test1 1)
      (should= -1 (index-backward test1 2)))))

(describe "list-to-dlist"
  (it "should make something"
    (should (list-to-dlist '(1 2 3 4 5))))
  (it "should create a list of the same length"
    (should= 5 (d-size (list-to-dlist '(1 2 3 4 5)))))
  (it "should be in the same order"
    (should= '(1 7 2 13 9) (show-dlist (list-to-dlist '(1 7 2 13 9))))))

(describe "delete"
    (it "should only delete one"
      (let [list (list-to-dlist '(1 2 3 3 4 5))]
        (delete list 3)
        (should= 5 (d-size list))
	(should= '(1 2 3 4 5) (show-dlist list))))
    (it "should reduce the size when it finds the element"
      (let [list (list-to-dlist '(1 2 3 4 5))]
        (delete list 3)
        (should= 4 (d-size list))
	(should= '(1 2 4 5) (show-dlist list))))
    (it "should not delete anything if the element isn't there"
      (let [list (list-to-dlist '(1 2 4 5))]
        (delete list 3)
        (should= 4 (d-size list))
	(should= '(1 2 4 5) (show-dlist list)))))

(describe "reverse"
  (let [list (list-to-dlist '(1 2 3 4 5))]
    (it "should reverse the whole list"
      (do
        (reverse list)
        (should= '(5 4 3 2 1) (show-dlist list))))))

(run-specs)
