#lang typed/racket

(require/typed racket/base
               [in-inclusive-range (->* (Integer Integer) (Integer) (Sequenceof Integer))])

(struct Coord ([x : Integer] [y : Integer])
  #:transparent)
(define-type CoordSet (Setof Coord))
(define-type Destiny (U 'live 'die 'ignore))
(struct Change ([destiny : Destiny] [coord : Coord])
  #:transparent)
(struct BBox ([lowerLeft : Coord] [upperRight : Coord])
  #:transparent)

(: unpack (-> BBox (values Integer Integer Integer Integer)))
(define (unpack bbox)
  (let* ([ll (BBox-lowerLeft bbox)]
         [ur (BBox-upperRight bbox)])
    (values (Coord-x ll) (Coord-y ll) (Coord-x ur) (Coord-y ur))))

(: live (-> Coord Change))
(define (live coord)
  (Change 'live coord))

(define r-pentomino
  (map live (list (Coord 0 0) (Coord 0 1) (Coord 1 1) (Coord -1 0) (Coord 0 -1))))

(define show-work #f)
(define generations 1000)

(define MaxInt (* generations 2))
(define MinInt (- MaxInt))
(define TinyBox (BBox (Coord MaxInt MaxInt) (Coord MinInt MinInt)))
(define Ignore (Change 'ignore (Coord MaxInt MaxInt)))

(: println (-> Any Void))
(define (println x) (display x) (display "\n"))

(: just (-> Destiny (Listof Change) (Setof Coord)))
(define (just type updates)
  (apply set (map Change-coord (filter (lambda ([e : Change]) (equal? type (Change-destiny e))) updates))))

(: enlarge-box (-> Coord BBox BBox))
(define (enlarge-box coord bbox)
  (define-values (minx miny maxx maxy) (unpack bbox))
  (define-values (x y) (values (Coord-x coord) (Coord-y coord)))
  (BBox (Coord (min minx x) (min miny y))
        (Coord (max maxx x) (max maxy y))))

(: bounding-box (-> CoordSet BBox))
(define (bounding-box liveSet)
  (foldl enlarge-box TinyBox (set->list liveSet)))

(: display-row (-> CoordSet Integer Integer Integer Void))
(define (display-row liveSet minx maxx y)
  (println 
   (apply string (for/list: : (Listof Char) ([x (in-inclusive-range minx maxx)])
                   (if (set-member? liveSet (Coord x y)) #\@ #\space)))))

(define esc-char #\u1b)

(define clear-screen-string
  (string esc-char #\[ #\2 #\J))

(define home-cursor-string
  (string esc-char #\[ #\; #\H))

(: display-board (-> CoordSet Void))
(define (display-board liveSet)
  (define-values (minx miny maxx maxy) (unpack (bounding-box liveSet)))
  (display clear-screen-string)
  (display home-cursor-string)
  (for ([y (in-inclusive-range maxy miny -1)])
    (display-row liveSet minx maxx y))
  (sleep (/ 1 30.)))

(: apply-updates (-> CoordSet (Listof Change) CoordSet))
(define (apply-updates liveSet updates)
  (set-subtract (set-union liveSet (just 'live updates)) (just 'die updates)))

(define offsets (list
                 (Coord  1  1) (Coord 1  0) (Coord 1 -1)
                 (Coord  0  1)              (Coord 0 -1)
                 (Coord -1  1) (Coord -1 0) (Coord -1 -1)))

(: eight (-> Coord (Listof Coord)))
(define (eight pos)
  (let ([x (Coord-x pos)]
        [y (Coord-y pos)])
    (map (lambda ([offset : Coord]) (Coord (+ x (Coord-x offset)) (+ y (Coord-y offset)))) offsets)))

(: compute-affected (-> (Listof Change) (Setof Coord)))
(define (compute-affected updates)
  (apply set (append-map (lambda ([u : Change]) (eight (Change-coord u))) updates)))

(: neighbor-count (-> (Setof Coord) Coord Integer))
(define (neighbor-count liveSet pos)
  (for/sum ([n (eight pos)])
	   (if (set-member? liveSet n) 1 0)))

(: not-Ignore? (-> Change Boolean))
(define (not-Ignore? x)
  (not (equal? Ignore x)))

(: compute-updates (-> CoordSet (Setof Coord) (Listof Change)))
(define (compute-updates liveSet affected)
  (filter not-Ignore?
	  (for/list: : (Listof Change) ([pos affected])
		    (let ([count (neighbor-count liveSet pos)])
		      (if (equal? count 2) Ignore
			(let ([alive (set-member? liveSet pos)])
			  (if (equal? count 3)
			      (if alive Ignore
				(Change 'live pos))
			    (if alive
				(Change 'die pos)
			      Ignore)
			    )))))))

(: generation (-> Integer CoordSet (Listof Change) Void))
(define (generation n liveSet updates)
  (if (> n 0) 
      (let* ([new-set (apply-updates liveSet updates)]
		      [affected (compute-affected updates)]
		      [new-updates (compute-updates new-set affected)]
		      )
	(if show-work (display-board new-set) "")
	(generation (- n 1) new-set new-updates))
    (void)))

(: run (-> Void))
(define (run)
  (let ([start (current-inexact-milliseconds)])
    (generation generations (set) r-pentomino)
    (let ([secs (/ (- (current-inexact-milliseconds) start) 1000)])
      (display (/ generations secs))
      (display " generations / sec")
      (display "\n"))))

(if show-work
    (run)
    (for ([unused (in-range 5)]) (run)))
