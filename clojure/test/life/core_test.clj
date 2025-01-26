(ns life.core-test
  (:require [clojure.test :refer :all]
            [life.rle :as rle]
            [life.core :as life]))

(def r-pentomino (str
                   "#N R-pentomino\n"
                   "#C A methuselah with lifespan 1103.\n"
                   "#C www.conwaylife.com/wiki/index.php?title=R-pentomino\n"
                   "x = 3, y = 0, rule = B3/S23\n"
                   "b2o$2ob$bo!"
                   ))

(def acorn (str
             "#comment Acorn\n"
             "x = 7, y = 3, rule = B3/S23\n"
             "bo5b$3bo3b$2o2b3o!\n"
             ))


(deftest rle-to-live-cells
  "Convert the run-length encoded pattern data into a list of live cells and compare"
  (testing "some constant patterns from the internet"
    (is (= #{'(-2 2) '(0 1) '(-3 0) '(-2 0) '(1 0) '(2 0) '(3 0)} (rle/rle acorn))
        "acorn value")
    (is (= #{'(0 0) '(0 1) '(1 1) '(-1, 0) '(0, -1)} (set (rle/rle r-pentomino)))
        "r-pentomino value")))

(def g1
  (let [acorn (rle/rle acorn)
        board (life/make-board acorn)
        x (print (:alive board))]
    x))
        
(deftest life-generation
  "execute a some generations of life and check the results"
  (testing "a couple generations of acorn"
    (is (= (7 8)
           (let [acorn (rle/rle acorn)
                 board (life/make-board acorn)
                 x (life/print-board board)
                 board (life/next-generation board)
                 g1 (count (:alive board))
                 board (life/next-generation board)
                 g2 (count (:alive board))]
                 (g1 g2))
           "live count"))))
