(ns life.core
  (:use [clojure.pprint :only [pprint]])
  (:use [clojure.set :only [union difference intersection]])
  (:require [clj-async-profiler.core :as prof])
  (:gen-class))


; a pos is a 2-integer 2-tuple vector, like [0, 0]
; alive is a set of alive positions
; changes is a set of [:key pos] pairs (vectors) where
; :key is one of [:birth :die]
(defrecord Board [alive changes])

; the offsets of the 8 neighbors
(def neighbor-offsets
  (for [x [-1 0 1]
        y [-1 0 1]
        :when (not (and (zero? x) (zero? y)))]
    [x, y]))

; the locations of the neighbors of the given position
(defn- eight-neighbor-positions [pos]
  (let [[x y] pos]
    (map
     (fn [offsets]
       (let [[xoffset, yoffset] offsets]
         [(+ x xoffset) (+ y yoffset)]))
     neighbor-offsets)))

; returns the coordiants and their neighbors
(defn- consider [coords]
  (into #{} (comp (mapcat eight-neighbor-positions)) coords))

; return the number of living neighbors for the given position
(defn- count-neighbors [board pos]
  (let [alive (:alive board)]
    (count (keep alive (eight-neighbor-positions pos)))))

(defn- changes [board key]
  (let [changes (:changes board)
        match-key (fn [[how pos]] (= how key))]
    (into #{} (comp (filter match-key) (map second)) (:changes board))))

; construct a new board after applying the to_birth and to_die sets
(defn- apply-changes [board]
  (let [alive (difference
               (union (:alive board) (changes board :birth))
               (changes board :die))]
    (Board. alive #{})))

(defn- compute-to-do [board pos]
  (let [count (count-neighbors board pos)
        alive (:alive board)]
    (cond
      (= count 3) (if (alive pos) [] [[:birth pos]])
      (= count 2) []
      :else (if (alive pos) [[:die pos]] []))))

; compute the next board from the current board
(defn- next-generation [board]
  (let [changes (into [] (map second) (:changes board))
        coords (consider changes)
        newboard (apply-changes board)
        updates (mapcat #(compute-to-do newboard %1) coords)]
    (assoc newboard :changes updates)))

(defn- compute-bbox [board]
  (let [coords (:alive board)
        x's (map first coords)
        y's (map second coords)]
      (if (empty? coords) [[0, 0], [1, 1]]
         [[(apply min x's) (apply min y's)]
          [(apply max x's) (apply max y's)]])))

(defn- print-board [board]
  (let [[[x1 y1][x2 y2]] (compute-bbox board)]
    (doseq [y (range y2 (dec y1) -1)]
      (doseq [x (range x1 (inc x2))]
        (if ((:alive board) [x y]) (print \*) (print \space)))
      (println))))

(def r-pentomino (set (map (fn [pos] [:birth pos]) #{[0 0] [0 1] [1 1] [-1 0] [0 -1]})))

(defn- clear-screen []
  ; clear screen
  (print (str (char 27) "[2J"))
  ; move cursor to the top left corner of the screen
  (print (str (char 27) "[;H")))

; seconds since the epoch as a double
(defn- now []
  (/ (System/currentTimeMillis) 1000.))

(defn show-board [board]
  (do
    (clear-screen)
    (print-board board)
    (Thread/sleep (/ 1000 30))))

(defn- show-nothing [board]
  nil)

(defn- run [show]
  (let [generations 1000
        start-board (Board. #{} r-pentomino)
        start-time (now)]
    (loop [board start-board gen 0]
      (show board)
      (if (< gen generations)
        (recur (next-generation board) (inc gen))))
    (println (/ generations (- (now) start-time)) "generations / sec")))

(defn -main
  "Play the game of life"
  [& args]
  (let [arg (first (conj (vec args) "run"))
        profile (= arg "profile")
        show (if (= arg "show") show-board show-nothing)
        times (if (= arg "show") 1 5)]
      (if profile
        (do
          (prof/profile (dotimes [i times] (run show)))
          (prof/serve-files 8080))
        (dotimes [i times] (run show)))))
