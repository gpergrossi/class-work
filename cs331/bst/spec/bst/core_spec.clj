(ns bst.core-spec
;  (:refer-clojure :exclude [])
  (:require [speclj.core :refer :all]
            [bst.core :refer :all])
;  (:import [bst.core ])
  )

;; # The Tests
;;
;; We are going to use [spelj](https://github.com/slagyr/speclj) for our tests.

(defn is-sorted [t]
  (if (= (:left t) nil)
    (if (= (:right t) nil)
      true
      (if (pos? (compare (:value (:right t)) (:value t)))
        true
        false
      )
    )    
    (if (neg? (compare (:value (:left t)) (:value t))) 
      (if (= (:right t) nil) 
        true
        (if (pos? (compare (:value (:right t)) (:value t)))
          true
          false
        )
      )
      false
    )
  )
)


(describe "make"
  (it "makes something"
    (should (make-tree))
    (should (make-node 3 "three"))))

(describe "size"
  (it "returns size"
    (should= (size (make-tree)) 0)
    (should= (size (add (make-tree) 5 "five")) 1)))

(def tree 
  (add 
    (add 
      (add 
        (add 
          (add (make-tree) 7 "seven") 
          3 "three")
        12 "twelve")
      4 "four")
    9 :nine)
  )

(describe "add" 
  (it "keeps the tree sorted"
    (should (is-sorted tree)))
  (it "sets size correctly"
    (should= (size tree) 5)
    (should= (size (add tree 9 "still nine")) 5)))

(describe "find"
  (it "finds things in the tree"
    (should= (find tree 12) "twelve"))
  (it "does not find things not in the tree"
    (should= (find tree 39) nil)))

(describe "find-key"
  (it "finds keys"
    (should= (find-key tree 9) "nine"))
  (it "does not find missing entries"
    (should= (find-key tree 13) nil)))

(describe "delete" 
  (it "deletes elements that exist"
    (should= (size (delete tree 9)) 4)
    (should (is-sorted (delete tree 9)))
    (should (is-sorted (delete tree 7)))
    (should (is-sorted (delete tree 3)))
    (should (is-sorted (delete tree 12)))
    (should (is-sorted (delete tree 4))))
  (it "does not delete missing elements"
    (should= (size (delete tree 10)) 5)
    (should (is-sorted (delete tree 10)))))

(describe "delete-value"
  (it "deletes a value that exists"
    (should= (size (delete-value tree 9)) 4)
    (should (is-sorted (delete-value tree 7))))
  (it "does not delete missing values"
    (should= 5 (size (delete-value tree 13)))))

(def tree2 (add (add (add (make-tree) 2 2) 3 3) 1 1))
(def tree-m (map-tree tree2 inc))

(describe "map-tree"
  (it "maps a tree"
    (should= (:value (:root tree-m)) 3)
    (should= (:value (:left (:root tree-m))) 2)
    (should= (:value (:right (:root tree-m))) 4)))

(run-specs)

