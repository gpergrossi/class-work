(ns first_one.core-spec
  (:require [speclj.core :refer :all ]
            [first_one.core :refer :all]))

(describe "Truth"
          (it "is true"
              (should true))

          (it "is not false"
              (should-not false)))

(describe "Foo"
         (it "return true when x > y"
             (should (foo 20 10))
             (should (foo 9999 12)))

         (it "does not return true when x < y"
             (should-not (foo 20 90))
             (should-not (foo 99 912))))

(describe "Abs"
          (it "makes negative numbers positive"
              (should (= (abs -10) 10) )
              (should (= (abs -2134) 2134)))
          (it "doesn't change positive numbers or zero"
              (should (= (abs 10) 10) )
              (should (= (abs 234) 234))
              (should (= (abs 0) 0))))

(describe "Bar"
      (it "adds two positive numbers"
          (should (= 30 (bar 10 20)))
      ;    (should (= 10 (bar -10 20)))
      ))

(run-specs)
