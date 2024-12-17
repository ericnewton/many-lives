# This implementation of the game-of-life is longer than the example
# given in the janet examples. Like all many-lives implementations,
# this version runs incrementally and can avoid re-processing sections
# of the board that do not change.
#
# It also prints the board dynamically, which is more fun to watch.
#

(defn- union [a b]
  (let [c (table/clone a)]
    (each x b
      (put c x 1))
    c))

(defn- difference [a b]
  (let (c (table/clone a))
    (each e b
      (put c e nil))
    c))

(defn- first [a]
  (in a 0))

(defn- second [a]
  (in a 1))

# the offsets of the 8 neighbors
(def- neighbor-offsets
  (seq [x :range [-1 2]
	y :range [-1 2]
	:when (not (and (zero? x) (zero? y)))]
       [x y]))

# the locations of the neighbors of the given coord
(defn- eight-neighbor-coords [[x y]]
  (map
   (fn [[xoffset yoffset]]
     [(+ x xoffset) (+ y yoffset)]) neighbor-offsets))

# returns set (array) of neighbors of a set of coordinates
(defn- consider [coords]
  (distinct (mapcat eight-neighbor-coords coords)))

# return the number of living neighbors for the given position
(defn- count-neighbors [alive coord]
  (count (fn [c] (in alive c)) (eight-neighbor-coords coord)))

(defn- changes [board key]
  (let [changes (in board :changes)
        match-key (fn [[how coord]] (= how key))]
    (map second (filter match-key changes))))

(defn- make-board [alive changes]
  {:alive alive :changes changes})

# construct a new board after applying the to_birth and to_die sets
(defn- apply-changes [board]
  (difference
   (union (in board :alive) (changes board :birth))
   (changes board :die)))

(defn- compute-change1 [alive coord]
  (let [count (count-neighbors alive coord)]
    (cond
      (= count 3) (if (in alive coord) [] [[:birth coord]])
      (= count 2) []
      :else (if (in alive coord) [[:die coord]] []))))

(defn- compute-changes [alive coords]
  (mapcat (fn [c] (compute-change1 alive c)) coords))

# compute the next board from the current board
(defn- next-generation [board]
  (let [changes (map second (in board :changes))
        coords (consider changes)
        new-alive (apply-changes board)
        updates (compute-changes new-alive coords)
       ]
    (make-board new-alive updates)))

(defn- compute-bbox [board]
  (let [coords (keys (in board :alive))
        all-x (map first coords)
        all-y (map second coords)]
      (if (empty? coords) [[0 0] [1 1]]
         [[(min ;all-x) (min ;all-y)]
          [(max ;all-x) (max ;all-y)]])))

(defn- print-board [board]
  (let [[[x1 y1][x2 y2]] (compute-bbox board)
	alive (in board :alive)
       ]
    (each y (range y2 (dec y1) -1)
      (each x (range x1 (inc x2))
        (if (in alive [x y]) (prin "*") (prin " ")))
      (print)
      (flush))))

(def- r-pentomino (map (fn [coord] [:birth coord]) [[0 0] [0 1] [1 1] [-1 0] [0 -1]]))
(def- esc "\x1b")
  
(defn- clear-screen []
  (prin
   # clear screen
   esc "[2J"
   # move cursor to the top left corner of the screen
   esc "[;H"))

(defn- show-board [board]
    (clear-screen)
    (print-board board)
    (os/sleep (/ 1 30)))

(defn- show-nothing [board]
  nil)

(defn- run [show]
  (let [generations 1000
        start-time (os/clock)]
    (var board (make-board @{} r-pentomino)) 
    (for gen 0 generations
      (do
        (set board (next-generation board))
	(show board)))
    (printf "%.2f generations / sec" (/ generations (- (os/clock) start-time)))))

(defn- main [& args]
  (let [arg (second (tuple ;args "run"))
	show (if (= arg "show") show-board show-nothing)
	times (if (= arg "show") 1 5)]
    (each i (range 0 times) (run show))))

