;;; CS 351 graph lab solution (in Clojure) ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; an adjacency list consists of a map of vertex labels to lists of
;; adj-v structs, where each adj-v struct is a vertex label (:to),
;; and the distance to that vertex (:dist)
(defstruct adj-v :to :dist)

(defn make-adj-list
  "Creates an adjacency list representation of the graph specified in s.
   The elements in s are taken 3 at a time, where each 3-tuple describes
   an edge of the graph as <from to distance> -- from and to are
   (unique) arbitrary vertex labels."
  [& s]
  (reduce (fn [m [x y d]]
	    (let [v1 (struct adj-v x d)
		  v2 (struct adj-v y d)]
	      (merge-with concat m {x [v2] y [v1]})))
	  {}
	  (partition 3 s)))

(defn find-tour
  "Finds a tour of the graph, given as an adjacency list. When found,
   return a vector where the first element is a seq of the vertices
   in the order they're traversed, and the second element is the distance
   of the tour. The tour returned isn't necessarily the shortest one."
  ([adj-list]
     (some #(find-tour adj-list [%] 0) (keys adj-list)))
  ([adj-list path dist]
     ;; (println path dist)   ; search trace
     (if (= (count path) (count adj-list))
       [path dist]
       (let [adj (adj-list (first path))]
         (some (fn [{t :to d :dist}]
                 (and (not (some #(= % t) path))
                      (find-tour adj-list (cons t path) (+ dist d))))
               adj)))))

;;; testing ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn test-tour
  "Test to see if tour is valid over the graph specified by adj-list,
   and if it is of length dist."
  ([adj-list tour dist]
     (when (and (= (count adj-list) (count tour))
                (= (count (distinct tour)) (count tour)))
       (test-tour adj-list (first tour) (rest tour) dist)))
  ([adj-list start path dist]
     (let [adj-start (adj-list start)
           next (first path)
           next-adjv (some #(if (= next (:to %)) %) adj-start)]
       (cond
        ;; if dist < 0 or next node is not in start's adj-list, bad path
        (or (< dist 0)
            (and (= dist 0) (not (empty? path)))
            (and (> dist 0) (not next-adjv)))
        false
        ;; found tour
        (= dist 0)
        true
        ;; accept vertex, recur for remainder of path
        :else
        (recur adj-list next (rest path) (- dist (:dist next-adjv)))))))

;;; some sample graphs and test cases ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; simple graph
(find-tour (make-adj-list 'a 'b 10 'b 'c 5 'c 'd 6))

;; from assignment writeup
(find-tour (make-adj-list "Chicago" "Plainfield" 30
                          "Chicago" "OakPark" 8
                          "Chicago" "Schaumburg" 30
                          "Chicago" "Evanston" 12
                          "OakPark" "Evanston" 14
                          "Schaumburg" "Evanston" 24))

;; no solution
(find-tour (make-adj-list "a" "b" 1
                          "a" "c" 1
                          "a" "d" 1))

;; somewhat larger graph
(def graph2 ["a" "b" 2
             "b" "c" 3
             "c" "d" 4
             "d" "e" 11
             "e" "f" 8
             "e" "g" 9
             "e" "h" 10
             "f" "i" 7
             "i" "h" 6
             "d" "h" 5
             "a" "e" 12])

(def graph2-adj-list (apply make-adj-list graph2))

(let [[tour length] (find-tour graph2-adj-list)]  
  (test-tour graph2-adj-list tour length))