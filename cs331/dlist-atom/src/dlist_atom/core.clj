(ns dlist-atom.core
  ; (:refer-clojure :exclude [pop peek])
)

;; # Introduction
;;
;; In this lab you will create a doubly linked list using atoms to
;; handle the immutability.  You will also use a sentinel to make
;; your code simpler.

;; The first thing you need is the wrapper class `DList` and the
;; node class `DNode`.

(defrecord DList [sentinel size])
(defrecord DNode [prev data next])

;; The DNode creator uses a feature in Clojure that allows functions to
;; have more than one parameter list.

(defn dnode 
  "Create a data node.  If one argument is provided, assume it is the data and make the previous
and next pointers nil."
  ([data]            (dnode nil data nil))
  ([prev data next]  (DNode. (atom prev) (atom data) (atom next))))

;; The DList creator will wrap the size in an atom so that it can
;; be changed, but the sentinel will not be changed; only the nodes
;; it points to will change.

(defn dlist []
  (let [sentinel (dnode 'sentinel)]
    (do 
      (reset! (:next sentinel) sentinel)
      (reset! (:prev sentinel) sentinel)
      (DList. sentinel (atom 0)))))
    
;; ## Accessors
;;
;; Dereferencing atoms is tedious and boring, which make it a ripe source
;; of bugs.  Use these accessor functions instead.

(defn d-sentinel "Return the sentinel field of a dlist."
  [xx] (:sentinel xx))

(defn d-size "Return the size of a dlist."
  [xx] 
  @(:size xx))

(defn reset-d-size! "Call reset on the size field of the dlist."
  [xx num]
  (reset! (:size xx) num))

(defn swap-d-size! "Call swap! on the size field of a dlist."
  [xx f]
  (swap! (:size xx) f))

;; # A getter/setter macro
;;
;; You don't have to understand this code, but for more advanced students this
;; should be interesting.  The above three functions need to be duplicated for
;; the next, prev, and data fields of DNode.  This involves a lot of repetition,
;; which is Bad.  So, this macro takes the "base name" of the functions and the
;; field on which it will operate, and then creates the three functions.
;;
;; If I were to use this macro for the size functions above, it would look like
;;
;; `(make-setter-getter d-size size)`
;;
;; Ask google about "clojure macros" to learn more about how this works.
;; Why write a program when you can write a program to write a program?

(defmacro make-setter-getter [name field]
  (let [fkw (keyword field)
        swapname (symbol (str "swap-" name "!"))
        resetname (symbol (str "reset-" name "!"))]
    `(do (defn ~name ~(str "Dereference the '" field "' field and return the result.")
           [xx#] @(~fkw xx#))
         (defn ~swapname ~(str "Calls swap! on the '" field "' field.")
           [xx# val#] (swap! (~fkw xx#) val#))
         (defn ~resetname ~(str "Calls reset! on the '" field "' field.")
           [xx# f#] (reset! (~fkw xx#) f#)))))

;; Now let's set up next, data, and prev.

(make-setter-getter d-next next)
(make-setter-getter d-data data)
(make-setter-getter d-prev prev)

;; ## Display
;;
;; A DList will necessarily be a circularly linked list, and will therefore crash the repl if you
;; try to print it.  To avoid that, I provide a special function for you.  All it does is return the
;; content of a dlist in a regular Clojure list.  But it also detects if an infinite loop has
;; occured.  

(declare show-dlist-aux)
(defn show-dlist "Return a list representation of the contents of a DList."
  [xx] (show-dlist-aux (d-sentinel xx) (-> xx d-sentinel d-next) 
                       (-> xx d-sentinel d-next d-next)))

(defn show-dlist-aux "Run through the data of a Dlist, stopping when reaching the sentinel or
discovering an infintite loop.  The runner goes twice as fast through the list; if it reaches
node we know we have an infinite loop."
  [sen node runner]
  (cond (identical? sen node) '()
        (identical? node runner) '(infinite-loop)
        :else (cons (d-data node) (show-dlist-aux sen (d-next node) (-> runner d-next d-next)))))

;; # Code
;;
;; You were probably wondering when you'd get to write some code, weren't you?
;; Here are the functions you need to write.  They are stub functions with doc strings to
;; tell you what they are supposed to do.  Note that elements are not DNodes.  The functions
;; will create any necessary DNodes.  Have fun!

;; To get you started, the first one is given.

;; Oh! One more thing.  If you run these from the repl, many of them will return a node, and cause
;; a stack overflow error because the repl tries to print everything and gets confused by the cycles.
;; Don't let that bother you.

(defn sure-list [xx]
  (if (nil? xx) (dlist) xx))

(defn close-node "Updates the nodes that this element points to so that they properly point back to it"
  [node]
    (do
      (reset-d-next! (d-prev node) node)
      (reset-d-prev! (d-next node) node)))

(defn insert-after "Insert an element into the dlist after the reference element."
  [xx ref elt]
    (let [xy (sure-list xx)]
      (close-node (dnode ref elt (d-next ref)))
      (swap-d-size! xy inc)
      xy))
    
(defn insert-before "Insert an element into the dlist before the reference element."
  [xx ref elt] (insert-after xx (d-prev ref) elt))

(defn insert-front "Insert an element into the front of a dlist."
  [xx elt] (let [xy (sure-list xx)] (insert-after xy (d-sentinel xy) elt)))

(defn insert-last "Insert an element into the back of a dlist."
  [xx elt] (let [xy (sure-list xx)] (insert-before xy (d-sentinel xy) elt)))

(defn insert-sorted "Insert an element in sorted order"
  ( [xx elt] (let [xy (sure-list xx)] (insert-sorted xy elt (-> xy d-sentinel d-next))) ) 
  ( [xx elt node] 
    (cond 
      (or (identical? (d-sentinel xx) node) (or (nil? elt) (> (d-data node) elt)))
        (insert-before xx node elt)
      :else (insert-sorted xx elt (d-next node)))))

(defn index-forward "Return if an element is in the list, going forward.  Return the index, starting from zero.
I.e., if it was the first element, return 0; second, return 1..."
  ( [xx elt] (index-forward xx elt (-> xx d-sentinel d-next) 0) )
  ( [xx elt node count]
    (cond
      (identical? (d-sentinel xx) node) nil
      (= (d-data node) elt) count
      :else (index-forward xx elt (d-next node) (inc count)))))

(defn index-backward "Return if an element is in the list, from the back.  Return the index, starting from negative one.
I.e., if it was the last element, return -1; penultimate, return -2..."
  ( [xx elt] (index-backward xx elt (-> xx d-sentinel d-prev) -1) )
  ( [xx elt node count]
    (cond
      (identical? (d-sentinel xx) node) nil
      (= (d-data node) elt) count
      :else (index-backward xx elt (d-prev node) (dec count)))))

(defn insert-list-after "Inserts a list of elements into the dlist after the reference element (efficiently)."
  ( [dlist ref list] (insert-list-after dlist ref list (d-next ref)))
  ( [dlist prev list last]
    (cond
      (empty? list) 
        (do
	  (reset-d-next! prev last)
          (reset-d-prev! last prev)
	  dlist)
      :else
        (do
          (swap-d-size! dlist inc)
          (let [nu-node (dnode prev (first list) nil)]
	    (reset-d-next! prev nu-node)
            (insert-list-after dlist nu-node (rest list) last))
	    dlist))))

(defn insert-list-before "Inserts a list of elements into the dlist before the referenve element (efficiently)."
  ( [dlist ref list] (insert-list-after dlist (d-prev ref) list (d-prev ref))))

(defn list-to-dlist "Given a Clojure list, return a DList with the same content."
  [list] (let [nu-dlist (dlist)] (insert-list-after nu-dlist (d-sentinel nu-dlist) list)))

(defn delete-node "Remove a node from its d-list by updating its neighbors to by-pass it."
  [xx node] 
    (do
      (reset-d-next! (d-prev node) (d-next node))
      (reset-d-prev! (d-next node) (d-prev node))
      (swap-d-size! xx dec))
      xx)

(defn delete "Find and remove an element from the dlist. 
Does nothing if the elment is not there. Uses sentinels, so it's very short."
  ( [xx victim] (delete xx victim (-> xx d-sentinel d-next)))
  ( [xx victim node]
    (cond 
      (identical? (d-sentinel xx) node) xx
      (= (d-data node) victim)
        (delete-node xx node)
      :else (delete xx victim (d-next node)))))

(defn reverse-node "Reverses a node in place, does not affect its neighbors in any way."
  [node] 
    (let [old-prev (d-prev node)]
      (reset-d-prev! node (d-next node))
      (reset-d-next! node old-prev)))

(defn reverse "Reverse the doubly linked list in place. No new DNode or DList records are created."
  ( [xx] 
    (reverse xx (d-next (d-sentinel xx)))
  )
  ( [xx node] 
    (let [old-next (d-next node)]
      (reset-d-next! node (d-prev node))
      (reset-d-prev! node old-next)
      (if-not (identical? (d-sentinel xx) node) (reverse xx old-next) xx)
    )
    xx
  )
)

(defn show-dlist-reverse "Like show-dlist, but returns the items in reverse order."
  [xx] (show-dlist (reverse xx)))

