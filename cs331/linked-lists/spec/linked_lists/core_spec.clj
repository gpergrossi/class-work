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
              (should= 10 (:car (Cons. 10 20))))

          (it "should have a cdr"
              (should= 20 (:cdr (Cons. 10 20))))

          (it "should be chainable"
              (should= 40 (-> (Cons. 10 (Cons. 20 (Cons. 30 40))) :cdr :cdr :cdr))))

(describe "insert-at-beginning"
          (it "creates a cons cell"
              (should-not= nil (insert-at-beginning 10 nil)))

          (it "should work with empty lists"
              (should= (Cons. 10 nil) (insert-at-beginning 10 nil) ))
          
          (it "should work with lists that have data"
              (let [xx (Cons. 10 (Cons. 20 (Cons. 30 nil)))]
                (should= (Cons. 5 xx) (insert-at-beginning 5 xx) ))))

(describe "insert-at-end"
          (it "creates a cons cell"
              (should-not= nil (insert-at-end 10 nil))
	  )
          (it "should work with empty lists"
	      (should= (Cons. 10 nil) (insert-at-end 10 nil))
	  )
	  (it "should work with lists that have data"
	      (let [xx (Cons. 10 (Cons. 20 (Cons. 30 nil)))]
	        (should= 40 (:car (:cdr (:cdr (:cdr (insert-at-end 40 xx)))))))
	  )
          (it "should handle nil inserts"
              (should= nil (:car (:cdr (insert-at-end 5 nil))))
	  )
)

(describe "sorted insert"
          (it "should sort smallest to largest"
	      (let [xx (Cons. 5 (Cons. 10 (Cons. 15 nil)))]
                (should= xx (sorted-insert 10 (Cons. 5 (Cons. 15 nil))) )
	        (should= xx (sorted-insert 15 (Cons. 5 (Cons. 10 nil))) )
	        (should= xx (sorted-insert 5 (Cons. 10 (Cons. 15 nil))) )
	      )
	  )
	  (it "should recycle memory"
	      (let [xx (Cons. 5 (Cons. 10 (Cons. 15 nil)))]
	        (should (identical? xx (:cdr (sorted-insert 0 xx))))
	      )
	  )
)

(describe "search"
          (let [xx (Cons. 5 (Cons. 10 (Cons. 15 nil)))]
	    (it "should find first element"
	        (should (search 5 xx)) 
	    )
	    (it "should find middle element"
	        (should (search 10 xx))
	    )
	    (it "should find last element"
	        (should (search 15 xx))
            )
	    (it "should not find missing element"
	        (should-not (search 1337 xx))
            )
	  )
)

(describe "delete"
          (let [xx (Cons. 5 (Cons. 10 (Cons. 10 (Cons. 15 nil))))]
            (it "should delete only one copy"
                (should= (Cons. 5 (Cons. 10 (Cons. 15 nil))) (delete 10 xx))
	    )
	  )
)

(describe "delete-all"
          (let [xx (Cons. 5 (Cons. 10 (Cons. 10 (Cons. 15 nil))))]
	    (it "should delete all"
                (should= (Cons. 5 (Cons. 15 nil)) (delete-all 10 xx))
	    )
	  )
)

(describe "efficient-delete"
          (let [xx (Cons. 5 (Cons. 10 (Cons. 10 (Cons. 15 nil))))]
            (it "should delete if it can"
                (should= (Cons. 5 (Cons. 10 (Cons. 15 nil))) (efficient-delete 10 xx))
	    )
	    (it "should return original if it can't delete"
	        (should (identical? xx (efficient-delete 1337 xx)))
	    )
	  )
)

(run-specs)
