(ns life.rle
  (:require [clojure.string :as str]))

;; Decode the following into coordinates

;; #N Acorn
;; #O Charles Corderman
;; #C A methuselah with lifespan 5206.
;; #C www.conwaylife.com/wiki/index.php?title=Acorn
;; x = 7, y = 3, rule = B3/S23
;; bo5b$3bo3b$2o2b3o!

(defrecord Decoder [start pos run board])

(defn- start [start]
  (Decoder. start start "" '()))

(defn- run [decoder]
  (let [r (:run decoder)]
    (if (= "" r) 1 (Integer/parseInt r))))

(defn- cells [decoder]
  (let [[x y] (:pos decoder)
        end (+ x (run decoder))
        more (map (fn [x] [x y]) (range x end))]
    (update decoder :board concat more)))

(defn- skip [decoder]
  (let [[x y] (:pos decoder)]
    (assoc decoder
           :pos [(+ x (run decoder)), y]
           :run "")
    ))

(defn- digit? [c]
  (and (>= 0 (compare \0 c)) 
       (>= 0 (compare c \9))))

(defn- decode1 [decoder c]
  (cond
    (digit? c) (update decoder :run str c)
    (= c \b) (skip decoder)
    (= c \o) (skip (cells decoder))
    (= c \$) (let [[x _] (:start decoder)
                   [_ y] (:pos decoder)]
               (assoc decoder
                      :pos [x, (- y (run decoder))]
                      :run ""))
    (= c \!) decoder
    :else (throw (Exception. (str "Unknown encoding character " c)))))

(defn- decode_rle [decoder line]
  (reduce decode1 decoder line))

(defn- half [s]
  (quot (Integer/parseInt s) 2))

(defn- top_decode [decoder raw]
  (let [line (str/trim raw)]
    (if (not (empty? line))
      (case (get line 0)
        ;; comments
        \# decoder
        ;; decode offsets
        \x (let [matches (re-matches #"x = (\d+), y = (\d+).*" line)]
             (if (not matches) 
               (throw (Exception. (str "Unable to parse " line)))
               (let [xoffset (- (half (get matches 1)))
                     yoffset (+ (half (get matches 2)) 1)]
                 (start [xoffset yoffset])
                 )))
        ;; decode run-length-encoded data
        (decode_rle decoder line))
      decoder)
    ))

(defn rle [encoded]
  (set (:board (reduce top_decode (start [0 0]) (str/split-lines encoded)))))
