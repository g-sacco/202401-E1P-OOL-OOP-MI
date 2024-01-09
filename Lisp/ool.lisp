;;;; Sacco Giacomo 899927
;;;;
#||
(def-class 'person nil '(fields (name "Eve") (age 21 integer)))
(def-class 'student '(person) '(fields (name "Eva Lu Ator") (university "Berkeley" string)) '(methods (talk (&optional (out *standard-output*)) (format out "My name is ~A~%My age is ~D~%" (field this 'name) (field this 'age)))))
(defparameter s0 (make 'student 'name "Vitto" 'age 21 'university "POLIMI"))
(def-class 'studente-bicocca '(student) '(methods (talk () (format t "Mi chiamo ~A, e studio alla Bicocca~%" (field this 'name)))) '(fields (university "UNIMIB")))
(defparameter s1 (make 'studente-bicocca 'name "Vitto" 'age 21 'university "POLIMI"))
||#

(defparameter *classes-specs* (make-hash-table))

(defun add-class-spec (name class-spec)
  (setf (gethash name *classes-specs*) class-spec))

(defun class-spec (name)
  (gethash name *classes-specs*))

;;; parents-check
;;; checks if parents is a list of classes
(defun parents-check (parents class-name)
  (cond
   ((equal parents NIL)
    NIL)
   ((not (symbolp (first parents)))
    (error "parents-check: ~A is not a symbol" (first parents)))
   ((not (class-spec (first parents)))
    (error "parents-check: ~A is not a class" (first parents)))
   ((equal (first parents) class-name)
    (error "parents-check: class-name can't be a parent of class-name"))
   ((parents-check (rest parents) class-name))
   )
)

;;; find-class-field
;;; given a class name and a field name, search the field name in the class
;;; and if it is found is returned otherwise return NIL
(defun find-class-field (field-name class-name)
  (let* ((class-fields (get-class-fields class-name T))
        (found-list (mapcar #'(lambda (class-field)
                                (if (equal field-name (first class-field))
                                    class-field)
                                ) class-fields)))
    (first (remove-if #'null found-list))))


;;; field-check
(defun field-check (field class-name)
  (let ((field-name (first field))
        (value (second field))
        (field-type (third field))) ; Assuming field-type is optional
    
    (cond
     ((not (symbolp field-name))
      (error "field-check: ~A is not a symbol" field-name))
     ((and (not (null value)) (not (atom value)) (not (listp value)))
      (error "field-check: the value ~A is not a constant or a self-evaluating object" value))
     ((not (null field-type))
      (if (or (is-class field-type) (equal field-type class-name))
          (if (not (is-instance value field-type))
              (error "field-check: value \"~A\" for field ~A is not of class ~A"
                     value field-name field-type))
        (if (not (typep value field-type))
            (error "field-check: value \"~A\" for field ~A is not of type ~A" 
                   value field-name field-type)
;          (let ((old-field (find-class-field field-name class-name)))
;            (if (and old-field (not (subtypep field-type (third old-field))))
;                (error "field-check: ~A is not a subtype of ~A" 
;                       field-type (third old-field))))
          )     
        )
      )
     )
    )
  )

;;; get-class-methods
(defun get-class-methods (class-name)
  (when class-name
    (let* ((class (class-spec class-name))
           (class-parents (first class))
           (class-methods (rest (second (second class))))
           (parents-methods (append-list (mapcar #'get-class-methods class-parents))))
                        
      (append class-methods parents-methods)
      )))

;;; get-method
(defun get-method(instance method-name)
  (let* ((class-name (second instance))
         (all-methods (get-class-methods class-name)))
    (when all-methods
      (let ((found-list (mapcar #'(lambda (method)
                                    (if (equal method-name (first method))
                                        method)) all-methods)))
        (first (remove-if #'null found-list))))
    )
  )

;;; rewrite-method-code
(defun rewrite-method-code (method-name method-spec)
  (append
   (list 'lambda)
   (list(append (list 'this) (first method-spec)))
   (list (first (rest method-spec)))))


;;; process-method
(defun process-method (method-name method-spec)
  ;MIRACLE
  (setf (fdefinition method-name)
        (lambda (this &rest arglist) ;this = istanza 
          (apply 
           (second (get-method this method-name)) ;funzione che ritorna il procedimento del metodo
           (append (list this) arglist))))
  (eval (rewrite-method-code method-name method-spec)))

;;; method-check
(defun method-check (method)
  (let ((method-name (first method))
        (arglist (second method))
        (form (third method)))
    (cond
     ((not (symbolp method-name))
      (error "method-check: ~A is not a symbol" method-name))
     ((not (listp arglist))
      (error "method-check: ~A is not a list" arglist))
     ((not (every (lambda (arg)
                    (cond
                     ((symbolp arg) T)
                     ((and (listp arg)
                           (every #'symbolp arg)) T)
                     (T NIL)))
                    arglist))
      (error "method-check: ~A is not a list of standard parameters" arglist))
     ((null form)
      (error "method-check: form can't be NIL")))

    
    )
)

;;; parts-check
(defun parts-check (parts class-name)
  (let* ((part (first parts))
         (part-type (first part))
         (part-fields (rest part)))      
    (cond 
     ((null parts) 
      NIL)
     ((not (listp parts)) 
      (error "parts-check: parts is not a list"))
     ((and 
       (not (equal part-type 'fields))
       (not (equal part-type 'methods)))
      (error "parts-check: a part must begin with 'fields' or 'methods'"))
     )
     
    (if (equal part-type 'fields)
        (mapcar #'(lambda (field) 
                  (field-check field class-name)
                  ) part-fields))
    (if (equal part-type 'methods)
        (mapcar #'method-check part-fields))
     
    (if (not (null parts))
        (parts-check (rest parts) class-name ))
    )
  )

;;; format-field-type
(defun format-field-type (parts)
  (when parts
    (let* ((part (first parts))
           (part-type (first part))
           (part-fields (rest part)))      
      (if (equal part-type 'fields)
          (let ((new-parts (append (list part-type) (mapcar  #'(lambda (field)
                                                                 (if (null (third field))
                                                                     (append field (cons T NIL))
                                                                   field)
                                                                 ) part-fields))))
            new-parts
         ; (list new-parts (first (rest parts)))
            )
        (format-field-type (rest parts))
        )
      )
    )
  )

;;; format-method
(defun format-method (parts)
  (when parts
    (let* ((part (first parts))
           (part-type (first part))
           (part-methods (rest part)))      
      (if (equal part-type 'methods)
          (let 
              ((new-methods (mapcar #'(lambda (method)
                                        (let ((name (first method))
                                              (arglist (second method))
                                              (form (third method)))
                                          (list name
                                           (process-method name (list arglist form))))
                                        ) part-methods)))
            
            (append (list part-type) new-methods))
            
        (format-method (rest parts)))
        )
    )
  )


;;; def-class
;TODO: check if every typed subclass field is the same or a smaller type compared
;  to the superclass' field
(defun def-class (class-name parents &rest parts)
  ;(let ((result (add-class-spec class-name (list parents (format-field-type parts)))))
    (cond 
     ((not (symbolp class-name)) 
      (error "def-class: class-name is not a symbol"))
     ((not (listp parents))
      (error "def-class: parents is not a list"))
     ((parents-check parents class-name)
      (error "def-class: parents-check"))
     ((parts-check parts class-name)
      (error "def-class: parts-check"))
     ;;; TODO: define a format to save the class
     ((add-class-spec class-name (list parents (list (format-field-type parts) (format-method parts))))
      class-name
      )
     )
    
    )

;;; is-class
(defun is-class (class-name)
  (if (class-spec class-name) T)
)

;;; assoc-list-format
;;; format a list as an associative list
(defun assoc-list-format (parameters)
  (if (null parameters)
      NIL
    (append (list (list (first parameters) (second parameters)))
            (assoc-list-format (cdr (rest parameters)))))
)


;;;
(defun append-list (list)
        (let* ((first-el (first list))
               (second-el (second list))
               (rest-el (rest (rest list))))
          (if (null first-el)
              NIL)
          (if (null second-el)
              first-el)
          (if (null rest-el)
              (append first-el second-el)
            (append (append first-el second-el) (append-list rest-el)))))
          
                          

;;; get-class-fields  !!!! DA RIVEDERE !!!!
;;; return a list containig all the fields of class including the inherited fields. 
;;; in case a field is defined more than one class pick the newest definition
(defun get-class-fields (class-name &optional (only-superclass NIL))
  (when class-name
    (let* ((class (class-spec class-name))
           (class-parents (first class))
           (class-fields (rest (first (second class))))
           (prov (mapcar #'get-class-fields class-parents))
           (parents-fields (append-list (mapcar #'get-class-fields class-parents)))
             ;rimuove parent-field se il field esiste in class fields
           (new-parents-fields (remove-if #'(lambda (parent-field) 
                                                (some #'(lambda (class-field)
                                                          (equal (first parent-field) (first class-field))
                                                          ) class-fields)
                                                ) parents-fields)))
             (if only-superclass
                 parents-fields
               (append class-fields parents-fields)
               ;(append class-fields (mapcar #'(lambda (parent-fields) 
               ;                                 parent-fields) parents-fields))
               )
             )))


;;; make-parameters
(defun make-parameters (parameters class-name)
  (if (null parameters)
      NIL
    (let 
        ((formatted-par (assoc-list-format parameters))
         (all-class-fields (get-class-fields class-name)))
      (cond 
       ;controlla se il nome parametro è presente nella classe of superclassi
       ((not (every #'(lambda (parameter)
                        (some #'(lambda (class-field)
                           (equal (first parameter) (first class-field))
                           ) all-class-fields)
                 ) formatted-par))
        (error "make-parameters: wrong parameters")))
      
      (every #'(lambda (parameter)
                 (every #'(lambda (class-field)
                            (if (equal (first parameter) (first class-field))
                                (if (not (equal (third class-field) T))
                                    (if (typep (second parameter) (third class-field))
                                        T
                                      (error "make-parameters: value \"~A\" for field ~A is not of type ~A"
                                             (second parameter) (first parameter) (third class-field)))
                                  T)
                              T)
                            ) all-class-fields)
                 ) formatted-par)
      formatted-par
      )
    )
  )

;;; make
(defun make (class-name &rest parameters)
  (if (not (is-class class-name))
      (error "make: ~A is not a class" class-name))
  
  (let 
      ((inst-par (make-parameters parameters class-name)))
    (append  (list 'oolinst class-name) inst-par)
    )  
)

;;; get-superclass
(defun get-superclass (class-name)
  (let* ((class (class-spec class-name))
         (class-parents (first class)))
    
    (remove-duplicates 
     (append 
      class-parents 
      (first (mapcar #'get-superclass class-parents)))
    ))
  )
    


;;; is-instance
(defun is-instance (instance &optional (class-name T))
  (let ((oolinst (first instance))
        (inst-class (second instance)))
    (if (null (cond
               ((not (equal oolinst 'oolinst))
                (error "is-instance: ~A doesn't define an instance" oolinst)) 
               ((not (is-class inst-class))
                (error "is-instance: ~A is not a class" inst-class))
               ((and (not (equal class-name T))
                     (not (member class-name (get-superclass inst-class)))
                     (not (equal inst-class class-name)))
                (error "is-instance: ~A is not a class or a superclass of ~A" 
                       class-name inst-class))
               )) T)
    )
  )

;;; field
(defun field (instance field-name)
  (let* ((class-name (second instance))
         (all-fields (get-class-fields class-name))
         (inst-parameters (cdr (cdr instance)))
         (inst-result (first (remove-if #'null 
                                 (mapcar #'(lambda (par)
                                             (if (equal field-name (first par))
                                                 par)
                                             ) inst-parameters)))))
    (cond 
     ((not (some #'(lambda (class-field) 
                          (equal field-name (first class-field))
                          ) all-fields))
      (error "field: ~A doesn't belong to ~A's fields" 
             field-name class-name))
     )
    (if (null inst-result) 
        (second (first (remove-if #'null 
                          (mapcar #'(lambda (par)
                                      (if (equal field-name (first par))
                                          par)
                                      ) all-fields))))
      (second inst-result))
    )
  )

;;; field*
(defun field* (instance field-names)
  (cond 
   ((not (is-instance instance))
    (error "field*: ~A is not an instance" instance))
   ((not (listp field-names))
    (error "field*: ~A is not a list" field-names))
   ((null field-names)
    (error "field*: ~A is an empty list" field-names))
   )
  (let ((field-value (field instance (first field-names))))
    (if (null (rest field-names))
        field-value
      (field* field-value (rest field-names))))
)
 




;set key=42 in hash table
;(setf (gethash 'key *classes-specs*) '42)


#||
(def-class 'person () '(fields (age 42) (name "Lilith")))
(def-class 'superhero '(person) '(fields (age 4092)))
(def-class 'doctor '(person))
(def-class 'fictional-character '(person) '(fields (age 60)))
(def-class 'time-lord '(doctor superhero fictional-character))
(defparameter the-doctor (make 'time-lord 'name "Dr. Who"))
(field the-doctor 'age)

field*
(def-class 'test-field* '() '(fields (inst NILL)))
(defparameter s3 (make 'test-field* 'inst "Niceee"))
(defparameter s2 (make 'test-field* 'inst s3))
(defparameter s1 (make 'test-field* 'inst s2))
(field* s1 '(inst inst inst))
||#