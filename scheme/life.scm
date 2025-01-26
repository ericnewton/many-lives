; moved imports into the command-line invocation
(import (srfi :1 lists))

(define (fmt . args)
  (display (apply format #f args)))

; Constant list of coordinates (x y) relative to a cell, (-1 -1) to (1 1)
(define window '((-1 -1) (-1  0) (-1  1)
		 ( 0 -1)         ( 0  1)
		 ( 1 -1) ( 1  0) ( 1  1)))

; apply an offset to a coordinate
(define (apply-offset x y offxy)
  (let ((offx (first offxy))
	(offy (second offxy)))
    (list (+ x offx) (+ y offy))))

; apply the offsets in window (above) to a coordinate (x y)
(define (neighbors coord)
  (let ((x (first coord))
	(y (second coord)))
    (map (lambda (offxy) (apply-offset x y offxy)) window)))

(define (1+ n)
  (+ 1 n))

; count the different elements of a list: return a hash table of counts
(define (frequencies lst)
  (let ((table (make-hash-table))
	(zero (lambda () 0)))
    (map
     (lambda (elem) (hash-table-update! table elem 1+ zero))
     lst)
    table))

; map the elements of a list into the keys of a hash-table where the
; value is #t
(define (set-of lst)
  (let ((result (make-hash-table)))
    (map (lambda (e) (hash-table-set! result e #t)) lst)
    result))

; Get the next state in the Game Of Life.
(define (tick state)
  (let ((cell-set (set-of state))
	(neighbor-set (frequencies (append-map neighbors state))))
    (hash-table-fold neighbor-set 
		     (lambda (coord count lst)
		       (if (or (= count 3)
			       (and (= count 2) (hash-table-exists? cell-set coord)))
			   (cons coord lst)
			   lst))
		     '())))


(define esc "\x1b;")

(define (clear-screen)
  (fmt "~a~a~a~a" 
	   esc "[2J" ; clear screen
	   esc "[;H" ; move cursor to the top left corner of the screen
	   ))

(define (pause)
  (thread-sleep! (/ 1 30.)))

(define (draw state x1 y1 x2 y2)
  ; Draw cells in the game of life from (x1, y1) to (x2, y2)
  (clear-screen)
  (let ((cellset (set-of state)))
    (do ((y y2 (- y 1)))
	((<= y y1) #t)
      (do ((x x1 (+ x 1)))
	  ((>= x x2) #t)
	(if (hash-table-exists? cellset (list x y))
	    (display "@")
	    (display " ")))
      (newline))
    (pause)
    ))


; time, in seconds, since then
(define (diff-now then)
  (exact->inexact (- (time->seconds (current-time)) (time->seconds then))))
  

(define (run n)
  (let ((r-pentomino '((0 0) (0 1) (1 1) (-1 0) (0 -1)))
	(cols 80)
	(lines 25)
	(generations 1000)
	(start (current-time)))
    (do ((i 0 (+ i 1))
	 (state r-pentomino (tick state)))
	((> i generations) #t)
      ; (draw state -40 -12 40 12)
      )
    (let ((diff (diff-now start)))
      (fmt "~a ~a generations / sec~%" diff (/ generations diff))
      diff)))

(map run (list 1 2 3 4 5))
