;;;; Sacco Giacomo 899927
;;;;

(defparameter *classes-specs* (make-hash-table))

(defun add-class-spec (name class-spec)
  (setf (gethash name *classes-specs*) class-spec))

(defun class-spec (name)
  (gethash name *classes-specs*))

(defun def-class (class-name parents part)
  (format t "Classe: ~a" class-name)
  (fresh-line)
  (format t "Classe: ~a" parents)
  )
