(ns life.core-test
  (:require [clojure.test :refer :all]
            [life.rle :as rle]))

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
    (is (= #{'(-2 2) '(0 1) '(-3 0) '(-2 0) '(1 0) '(2 0) '(3 0)} (set (rle/rle acorn)))
        "acorn value")
    (is (= #{'(0 0) '(0 1) '(1 1) '(-1, 0) '(0, -1)} (set (rle/rle r-pentomino)))
        "r-pentomino value")))
        
