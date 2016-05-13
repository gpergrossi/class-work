(ns bst.core)

;; # Introduction
;;
;; In this lab you get to write a BST like the one we did in class, only
;; this time it is a dictionary structure and not a set.
;; As such, the "data" element from before will have a key and value instead.

(defrecord BST [root size])
(defrecord BNode [left key value right])

(defn make-node
  ([key value]  (make-node nil key value nil))
  ([left key value right] (BNode. left key value right))
  )

(defn make-tree []
  (BST. nil 0))

;; # Size
;;
;; A warmup function.

(defn size "Return the size of the tree."
  [t]
  (:size t))

;; # Print
;;
;; Returns a string representing the tree in an easily readable, in-line format

(declare print-node)

(defn print-tree "Returns the tree in a string"
  [t]
    (str (print-node (:root t)) " size: " (:size t)))

(defn print-node "Returns the node in a string"
  [n]
    (cond (= n nil) "X"
      (and (= (:left n) nil) (= (:right n) nil)) (str "<[" (:key n) " " (:value n) "]>")
      :else (str "<" (print-node (:left n)) " [" (:key n) " " (:value n) "] " (print-node (:right n)) ">")))

;; # Add
;;
;; The nodes will be entered into the tree on the basis of their key.
;; If someone tries to add a key that is already there, we replace the value
;; with the new entry.

(declare add-aux)

(defn add "Add a key and value to the BST."
  [bst nu-key nu-val]
    (let [[nu-node size-update] (add-aux (:root bst) nu-key nu-val)]
      (if (identical? nu-node (:root bst)) bst 
	(BST. nu-node (+ size-update (:size bst))))))

(defn add-aux "returns a pair including the new node with the key-value pair added and a number 0 or 1 whether the tree grew"
  [node nu-key nu-val]
    (cond (= node nil) [(BNode. nil nu-key nu-val nil) 1]
      (= (:key node) nu-key)
        (if (= (:value node) nu-val) [node 0]
	  [(BNode. (:left node) nu-key nu-val (:right node)) 0])
      (pos? (compare (:key node) nu-key))
        (let [[nu-left size-update] (add-aux (:left node) nu-key nu-val)]
	  (if (identical? (:left node) nu-left) [node 0]
	    [(BNode. nu-left (:key node) (:value node) (:right node)) size-update]))
      :else
        (let [[nu-right size-update] (add-aux (:right node) nu-key nu-val)]
	  (if (identical? (:right node) nu-right) [node 0]
	    [(BNode. (:left node) (:key node) (:value node) nu-right) size-update]))))

;; # Find
;;
;; We need two versions of find.  The first one takes a key and returns the
;; value.  The second takes a value and returns the key.  Note that the second
;; version of the function must search the entire tree!  If the search item is not
;; there, return nil.

(declare find-aux)

(defn find "Look for a key and return the corresponding value."
  [bst look-key] (find-aux (:root bst) look-key))

(defn find-aux
  [node look-key]
    (cond (= node nil) nil
    (= (:key node) look-key) (:value node)
    (pos? (compare (:key node) look-key)) (find-aux (:left node) look-key)
    :else (find-aux (:right node) look-key)))

(declare find-key-aux)

(defn find-key "Look for a value and return the corresponding key."
  [bst look-value] (find-key-aux (:root bst) look-value))

(defn find-key-aux
  [node look-value]
    (cond (= node nil) nil
    (= (:value node) look-value) (:key node)
    :else
      (or (find-key-aux (:left node) look-value)
         (find-key-aux (:right node) look-value))))

;; # Delete
;;
;; Similiarly, we have two versions of delete.  Please use the predecessor node if
;; you need to delete a child with two elements.

(defn get-last [node] (if (= (:right node) nil) node (get-last (:right node))))
(defn delete-last [node] (if (= (:right node) nil) (:left node) (BNode. (:left node) (:key node) (:value node) (delete-last (:right node)))))

(defn delete-node
  [node]
    (cond 
      (= (:left node) nil) (:right node)
      (= (:right node) nil) (:left node)
      :else (let [predecessor (get-last (:left node))] (BNode. (delete-last (:left node)) (:key predecessor) (:value predecessor) (:right node)))))

(declare delete-aux)

(defn delete [bst victim]
  (let [nu-node (delete-aux (:root bst) victim)]
    (if (identical? (:root bst) nu-node) bst (BST. nu-node (dec (:size bst))))))

(defn delete-aux
  [node victim]
    (cond 
      (= node nil) nil
      (= (:key node) victim) (delete-node node)
      (pos? (compare (:key node) victim))
        (let [nu-left (delete-aux (:left node) victim)]
	  (if (identical? (:left node) nu-left) node (BNode. nu-left (:key node) (:value node) (:right node))))
      :else
        (let [nu-right (delete-aux (:right node) victim)]
	  (if (identical? (:right node) nu-right) node (BNode. (:left node) (:key node) (:value node) nu-right)))))

(declare delete-value-aux)

(defn delete-value
  [bst victim]
    (let [nu-node (delete-value-aux (:root bst) victim)]
      (if (identical? (:root bst) nu-node) bst (BST. nu-node (dec (:size bst))))))

(defn delete-value-aux
  [node victim]
    (cond
      (= node nil) nil
      (= (:value node) victim) (delete-node node)
      :else
        (let [nu-left (delete-value-aux (:left node) victim)]
	  (if (not (identical? (:left node) nu-left)) (BNode. nu-left (:key node) (:value node) (:right node))
	    (let [nu-right (delete-value-aux (:right node) victim)]
	      (if (identical? (:right node) nu-right) node (BNode. (:left node) (:key node) (:value node) nu-right)))))))

;; # Map Tree
;;
;; This function takes a tree t and maps a function f over it.
;; If your tree is ((x 3 x) 5 ((x 7 x) 6 x)), then (map-tree t inc)
;; will return ((x 4 x) 6 ((x 8 x) 7 x))

(declare map-tree-aux)

(defn map-tree
  [t f] (BST. (map-tree-aux (:root t) f) (:size t)))

(defn map-tree-aux
  [n f]
  (if (= n nil) nil
  (BNode. (map-tree-aux (:left n) f) (:key n) (f (:value n)) (map-tree-aux (:right n) f))))


  
