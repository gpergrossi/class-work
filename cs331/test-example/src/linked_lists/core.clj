(ns linked_lists.core)

;; # Introduction
;;
;; This is a prequel to the linked list lab.  Our purpose here
;; is to show what tests look like in a somewhat more controlled
;; environment.

;; We provide a list record, and a stub function that you will
;; complete to make the tests work.

;; # The List
;;
;; The functions `first`, `rest`, and `next` are already taken.
;; We could override them, but it is likely that our own test cases
;; will want to use Clojure's built-in lists for comparison.  So
;; we will use the historic names.
;;
;; + `Cons` is the name of a pair.
;; + `car` is the name of the data element
;; + `cdr` is the name of the pointer to the next element
;;
;; We will use `nil` to represent an empty list.

(defrecord Cons [car cdr])


;; # Insert at Beginning
;;
;; To insert at the beginning of the list, we create
;; a new cons cell and point it to the target list.
;;
;; The function accepts the correct number of arguments, but just returns `nil`.
;; This is known as a _stub function_.  Here's what you should do now:
;;
;; + Try running `lein spec` first to see how the tests look when they fail.
;;
;; + Next, write the function.  Hint: the body should be
;;
;; `(Cons. elt xx)`
;;
;; + Run `lein spec` again to see how the tests look when they pass.
;;
;; + Once you "get it", you can move on to the real linked list lab.
;;
;; For more information, see the pdf that came with the linked list lab.

(defn insert-at-beginning [elt xx]
  "Create a new Cons with element `elt` and list `xx`."
  (Cons. elt xx))
;  nil)


