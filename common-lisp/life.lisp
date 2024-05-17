;#! /usr/bin/env sbcl --script

(declaim (optimize (speed 3) (debug 0) (safety 0)))

(defstruct (cell
             (:type (vector integer))
             (:constructor new-cell (x y)))
  (x 0 :type integer)
  (y 0 :type integer))

(defconstant r-pentomino '((0 0) (0 1) (1 1) (-1 0) (0 -1)))
(defconstant generations 1000)
(defconstant bbox '(80 25))

(defun println (obj)
  (princ obj)
  (terpri))

; https://stackoverflow.com/questions/4882361/which-command-could-be-used-to-clear-screen-in-clisp
(defun cls()
  (format t "~A[H~@*~A[J" #\escape))

(defun display-live (live)
  (cls)
  (destructuring-bind (width height) bbox
    (let ((halfw (floor width 2))
	  (halfh (floor height 2)))
      (dotimes (y height)
	(dotimes (x width)
	  (let ((coord (new-cell (- x halfw) (- halfh y))))
	    (if (gethash coord live)
	       	(princ "x")
	       	(princ ".")
		)))
	(terpri))))
  (sleep (/ 1 30)))

(defconstant neighbor-offsets
  '((-1  1) (0  1) (1  1)
    (-1  0)        (1  0) 
    (-1 -1) (0 -1) (1 -1)))

(defun neighbors (cell)
  (let ((x (cell-x cell))
	(y (cell-y cell)))
    (declare (type integer x y))
    (map 'list
	   (lambda (xyoffsets)
	     (new-cell
	      (+ x (first xyoffsets))
	      (+ y (second xyoffsets))))
	   neighbor-offsets)))

(defun evolve (cells)
  (let* ((size (hash-table-size cells))
	 (counts (make-hash-table :size size :test #'equalp))
	 (result (make-hash-table :size size :test #'equalp)))
    (maphash
     (lambda (cell ignored)
       ; increment counts for all cell neighbors
       (map nil	(lambda (n) (incf (gethash n counts 0)))
	(neighbors cell)))
     cells)
    (maphash
     (lambda (cell count)
       ; determine cell status for next generation
       (if (= count 3)
	   (setf (gethash cell result) t)
	   (if (= count 2)
	       (if (gethash cell cells)
		   (setf (gethash cell result) t)))))
     counts)
    result))

(defun recurse (cells generation-count)
  ; (display-live cells bbox)
  (if (eq generation-count 0)
      cells
      (recurse (evolve cells) (1- generation-count))))

(defun start ()
  (let ((seed (map 'list (lambda (x) (apply #'new-cell x)) r-pentomino))
	(cells (make-hash-table :test #'equalp)))
    (loop for c in seed
	  do (setf (gethash c cells) t))
    (recurse cells generations)
    ))

(defun perf (round)
  (let ((start (get-internal-run-time))
	(ignored< (start))
	(end  (get-internal-run-time)))
    (float (/ generations (/ (- end start) internal-time-units-per-second)))))
    
(defun runtimes ()
  (map 'list
       #'perf
       '(1 2 3 4 5)))

(defun main ()
  (let ((all (runtimes)))
    (format t "~d generations / sec"
	    (ceiling (second (sort all #'>)))))
  (terpri))

(sb-ext:save-lisp-and-die "life" :toplevel #'main :executable t)

  
