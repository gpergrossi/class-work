(ns fifolifo.core-spec
  (:refer-clojure :exclude [pop peek])
  (:require [speclj.core :refer :all]
            [fifolifo.core :refer :all])
  (:import [fifolifo.core Stack Queue]))

;; # The Tests
;;
;; We are going to use [spelj](https://github.com/slagyr/speclj) for our tests.

(describe "make-stack"
  (it "should create something"
    (should (make-stack))
  )

  (it "should have empty components."
    (should= (Stack. nil 0) (make-stack))
  )
          
  (it "should have a size of zero."
    (should= 0 (stack-size (make-stack)))
  )
)


(describe "stack-size"
  (it "should return the size"
    (should= 3 (stack-size (push (push (push (make-stack) 3) 12) 18)))
  )
)

(describe "push"
  (it "should increment stack size"
    (let [stk (push (make-stack) 1)]
      (should= 1 (stack-size stk))
      (should= 2 (stack-size (push stk 2)))
    )
  )
)

(describe "pop"
  (it "should decrement stack size"
    (let [stk (push (push (push (make-stack) 1) 2) 3)]
      (should= 3 (stack-size stk))
      (should= 2 (stack-size (pop stk)))
      (should= 1 (stack-size (pop (pop stk))))
      (should= 0 (stack-size (pop (pop (pop stk)))))
      (should= 0 (stack-size (pop (pop (pop (pop stk))))))
    )
  )
)

(describe "top"
  (it "should return the top"
    (let [s 'symbol]
      (should (identical? s (top (push (make-stack) s))))
    )
  )
)

(describe "stack order"
  (it "should add and remove elements in lifo order"
    (let [stk (push (push (push (make-stack) 8) 27) 13)]
      (should= 13 (top stk))
      (should= 27 (top (pop stk)))
      (should= 8 (top (pop (pop stk))))
      (should= nil (top (pop (pop (pop stk)))))
    )
  )
)

(describe "make-queue"
  (it "should create something."
    (should (make-queue))
  )

  (it "should have empty components."
    (should= (Queue. nil nil 0) (make-queue))
  )
          
  (it "should have a size of zero."
    (should= 0 (stack-size (make-stack)))
  )
)

(describe "queue-size"
  (it "should return the size"
    (should= 3 (queue-size (enqueue (enqueue (enqueue (make-queue) 3) 3) 3)))
  )
)

(describe "enqueue"
  (it "should increment queue size"
    (let [q (enqueue (make-queue) 'first)]
      (should= (inc (queue-size q)) (queue-size (enqueue q 'second)))
    )
  )
  (it "should share memory"
    (let [first 'first second 'second third 'third]
      (let [q (enqueue (enqueue (enqueue (make-queue) first) second) third)]
        (should (identical? first (peek q)))
	(should (identical? second (peek (dequeue q))))
	(should (identical? third (peek (dequeue (dequeue q)))))
	(should= nil (peek (dequeue (dequeue (dequeue q)))))
	(should= nil (peek (dequeue (dequeue (dequeue (dequeue q))))))
      )
    )
  )
)

(describe "dequeue"
  (it "should decrement queue size"
    (should= 2 (queue-size (dequeue (enqueue (enqueue (enqueue (make-queue) 3) 2) 1))))
    (should= 0 (queue-size (dequeue (make-queue))))
  )
)

(describe "peek"
  (it "should be working" ;tests in the enqueue test
    (should true)
  )
)

(run-specs)

