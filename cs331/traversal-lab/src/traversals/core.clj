(ns traversals.core)

;; Given Code

(defrecord BNode [left data right])

(defn add [t elt]
   (cond (nil? t)          (BNode. nil elt nil)
         (= elt (:data t)) t
         (< elt (:data t)) (BNode. (add (:left t) elt) (:data t) (:right t))
         :else             (BNode. (:left t) (:data t) (add (:right t) elt))))

;; A fast way to make trees is to use the code
;; (reduce add nil '(4 2 3 5 9))
;;
;; Use (reduce #(str "(" %1 " " %2 ")") "0" '(1 2 3)) to get an idea what it's doing.

;; # Your Code

(defn preorder 
  "Outputs a list containing the preorder traversal of the given tree." 
  [t]
  nil)

(defn postorder 
  "Outputs a list containing the postorder traversal of the given tree." 
  [t]
  nil)

(defn inorder 
  "Outputs a list containing the in-order traversal of the given tree." 
  [t]
  nil)

(defn levelorder 
  "Outputs a list containing the level-order traversal of the given tree." 
  [t]
  nil)

(defn frontier 
  "Outputs a list containing the frontier of the given tree." 
  [t]
  nil)

(defn map-tree
  "Create a new tree by applying the given function to all the elements."
  [f t]
  nil)
