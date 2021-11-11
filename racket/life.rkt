#lang racket

(define r-pentomino
  (map (lambda x (cons 'live x)) (list '(0 0) '(0 1) '(1 1) '(-1 0) '(0 -1))))

(define show-work #f)
(define generations 1000)

(define (println x) (display x) (display "\n"))

(define (just type updates)
  (apply set (map cadr (filter (lambda (e) (equal? type (car e))) updates))))

(define (bounding-box liveSet)
  (let* ([xs (set-map liveSet car)]
         [ys (set-map liveSet cadr)])
    (values (apply min xs) (apply min ys) (apply max xs) (apply max ys))))

(define (display-row liveSet minx maxx y)
  (println
   (apply string (for/list ([x (in-inclusive-range minx maxx)])
			   (if (set-member? liveSet (list x y)) #\@ #\space)))))

(define esc-char #\u1b)

(define clear-screen-string
  (string esc-char #\[ #\2 #\J))

(define home-cursor-string
  (string esc-char #\[ #\; #\H))

(define (display-board liveSet)
  (define-values (minx miny maxx maxy) (bounding-box liveSet))
  (display clear-screen-string)
  (display home-cursor-string)
  (for ([y (in-inclusive-range maxy miny -1)])
       (display-row liveSet minx maxx y))
  (sleep (/ 1 30.)))

(define (apply-updates liveSet updates)
  (set-subtract (set-union liveSet (just 'live updates)) (just 'die updates)))

(define (eight pos)
  (for*/list ([x (in-inclusive-range -1 1)]
	   [y (in-inclusive-range -1 1)]
	   #:when (not (and (equal? x 0) (equal? y 0)))
	   )
	(list (+ (car pos) x) (+ (cadr pos) y))))


(define (compute-affected updates)
  (apply set (append-map (lambda (u) (eight (cadr u))) updates)))

(define (neighbor-count liveSet pos)
  (for/sum ([n (eight pos)])
	   (if (set-member? liveSet n) 1 0)))

(define (not-null? x)
  (not (null? x)))

(define (compute-updates liveSet affected)
  (filter not-null?
	  (for/list ([pos affected])
		    (let ([count (neighbor-count liveSet pos)])
		      (if (equal? count 2) null
			(let ([alive (set-member? liveSet pos)])
			  (if (equal? count 3)
			      (if alive null
				(list 'live pos))
			    (if alive
				(list 'die pos)
			      null)
			    )))))))

(define (generation n liveSet updates)
  (if (> n 0) 
      (let* ([new-set (apply-updates liveSet updates)]
		      [affected (compute-affected updates)]
		      [new-updates (compute-updates new-set affected)]
		      )
	(if show-work (display-board new-set) "")
	(generation (- n 1) new-set new-updates))
    ""))

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
