;;;; Sacco Giacomo 899927

;;; file ool.lisp

;;; OOA in Common Lisp

;;; Classes' HASH Table
(defparameter *classes-specs* (make-hash-table))

(defun add-class-spec (name class-spec)
  (setf (gethash name *classes-specs*) class-spec))

(defun class-spec (name)
  (gethash name *classes-specs*))

;;; Parents-check
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
;;; given a class name and a field name, search the field name in the
;;; class and if it is found is returned otherwise return NIL
(defun find-class-field (field-name class-name)
  (let* ((class-fields (get-class-fields class-name))
         (found-list (mapcar #'(lambda (class-field)
                                 (if (equal field-name (first class-field))
                                     class-field))
                             class-fields)))
    (first (remove-if #'null found-list))))


;;; Field-check
;;; Checks a given field (field-name value field-type), if
;;; everything is fine returns NIL otherwise gives an error
(defun field-check (field class-name parents)
  (let ((field-length (list-length field))
        (field-name (first field))
        (value (second field))
        (field-type (third field)))
    
    (cond
      ((or (< field-length 2) (> field-length 3))
       (error "field-check: ~A is not a valid field length" field-length))
      ((not (symbolp field-name))
       (error "field-check: ~A is not a symbol" field-name))
      ((and (not (null value)) (not (atom value)) (not (listp value)))
       (error "field-check: the value ~A is not a constant or a
      self-evaluating object" value))
      ((not (null field-type))
       (if (or (is-class field-type) (equal field-type class-name))
           (if (not (is-instance value field-type))
               (error "field-check: value \"~A\" for field ~A is not
      of class ~A" value field-name field-type))
           (if (not (typep value field-type))
               (Error "field-check: value \"~A\" for field ~A is not
      of type ~A"  value field-name field-type)
               (let ((old-field (first (mapcar #'(lambda (class-name)
                                                   (find-class-field
                                                    field-name class-name))
                                               parents))))
                 (if (and old-field (not
                                     (subtypep field-type
                                               (third old-field))))
                     (error "field-check: ~A is not a subtype of ~A"
                            field-type (third old-field))))
               ))))))

;;; append-list
;;; given a list of lists appends each element in a single list
(defun append-list (main-list)
  (when main-list
    (let* ((first-el (first main-list))
           (second-el (second main-list))
           (rest-el (rest (rest main-list))))
      (if (null first-el)
          NIL)
      (if (null second-el)
          first-el)
      (if (null rest-el)
          (append first-el second-el)
          (append (append first-el second-el) (append-list rest-el))))))

;;; get-class-methods
;;; given a class name, it returns a list containing all of his methods 
(defun get-class-methods (class-name)
  (if (is-class class-name)
      (let* ((class (class-spec class-name))
             (class-parents (first class))
             (class-methods (rest (second (second class))))
             (parents-methods (append-list (mapcar #'get-class-methods
                                                   class-parents))))
        
        (append class-methods parents-methods))
      (error "get-class-methods: ~A is not a class" class-name)
      ))


;;; get-method
;;; given an instance and a method name, it returns the method
;;; associated to the instance with method-name as a name
(defun get-method(instance method-name)
  (let* ((class-name (second instance))
         (all-methods (get-class-methods class-name)))
    (when all-methods
      (let ((found-list (mapcar #'(lambda (method)
                                    (if (equal
                                         method-name (first method))
                                        method))
                                all-methods)))
        (first (remove-if #'null found-list))))
    )
  )

;;; rewrite-method-code
;;; given method-name and method-spec (arglist + form), it returns a
;;; lambda function with the "this" argument added
(defun rewrite-method-code (method-name method-spec)
  (if (symbolp method-name)
      (append
       (list 'lambda)
       (list (append (list 'this) (first method-spec)))
       (list (first (rest method-spec))))))


;;; process-method
;;; given method-name and method-spec (arglist + form), it adds the
;;; function definition of method-name and binds to it a lambda
;;; function representing the given method, than it evaluates the
;;; rewritten method
(defun process-method (method-name method-spec)
  (setf (fdefinition method-name)
        (lambda (this &rest arglist) ;this = instance
          (apply
           (second (get-method this method-name))
           (append (list this) arglist))))
  (eval (rewrite-method-code method-name method-spec)))

;;; method-check
;;; checks if the given method is valid, if it's not returns an error
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
                       ((symbolp arg)
                        T)
                       ((and (listp arg) (every #'symbolp arg))
                        T)
                       (T NIL)))
                   arglist))
       (error "method-check: ~A is not a list of standard parameters"
              arglist))
      ((null form)
       (error "method-check: form can't be NIL")))

    
    )
  )

;;; parts-check
;;; checks if the given part is valid, than based on part-type
;;; (methods or fields) launches field-check and method-check on each
;;; element using mapcar
(defun parts-check (parts class-name parents)
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
                    (field-check field class-name parents))
                part-fields))
    (if (equal part-type 'methods)
        (mapcar #'method-check part-fields))

    (if (not (null parts))
        (parts-check (rest parts) class-name parents))
    )
  )

;;; format-field-type
;;; given a list of parts (methods and fields) select the fields list
;;; and adds T to the fields without a specified type, than returns
;;; the updated fields list
(defun format-field-type (parts)
  (when parts
    (let* ((part (first parts))
           (part-type (first part))
           (part-fields (rest part)))      
      (if (equal part-type 'fields)
          (let ((new-parts
                  (append (list part-type)
                          (mapcar  #'(lambda (field)
                                       (if (null (third field))
                                           (append field
                                                   (cons T NIL))
                                           field))
                                   part-fields))))
            new-parts
            )
          (format-field-type (rest parts))
          )
      )
    )
  )

;;; format-method
;;; given a list of parts (methods and fields) select the methods
;;; list, than runs "process-method" on each method and returns an
;;; associative list containing the method-name and the related
;;; function returned by "process-method"
(defun format-method (parts)
  (when parts
    (let* ((part (first parts))
           (part-type (first part))
           (part-methods (rest part)))      
      (if (equal part-type 'methods)
          (let 
              ((new-methods
                 (mapcar #'(lambda (method)
                             (let ((name (first method))
                                   (arglist (second method))
                                   (form (third method)))
                               (list name
                                     (process-method name
                                                     (list arglist
                                                           form)))))
                         part-methods)))
            
            (append (list part-type) new-methods))

          (format-method (rest parts)))
      )
    )
  )


;;; def-class
;;; check if class-name, parents and part are correct, than adds the
;;; class to centralized location: *classes-specs*
(defun def-class (class-name parents &rest parts)
  (cond 
    ((not (symbolp class-name)) 
     (error "def-class: class-name is not a symbol"))
    ((not (listp parents))
     (error "def-class: parents is not a list")))
  
  (parents-check parents class-name)
  (parts-check parts class-name parents)
  
  (if (add-class-spec class-name
                      (list parents
                            (list (format-field-type parts)
                                  (format-method parts))))
      class-name)
  )


;;; is-class
;;; if the given class-name represents a defined class, returns T
(defun is-class (class-name)
  (if (class-spec class-name) T)
  )

;;; assoc-list-format
;;; format a list of elmentsts, associate them two by two
;;; (1 2 3 4) -> ((1 2) (3 4))
(defun assoc-list-format (parameters)
  (if (null parameters)
      NIL
      (append (list (list (first parameters) (second parameters)))
              (assoc-list-format (cdr (rest parameters)))))
  )

;;; get-class-fields
;;; return a list containig all the fields of a class including the
;;; inherited fields.  
(defun get-class-fields (class-name)
  (when class-name
    (let* ((class (class-spec class-name))
           (class-parents (first class))
           (class-fields (rest (first (second class))))
           (parents-fields (append-list
                            (mapcar #'get-class-fields class-parents))))
      (append class-fields parents-fields)
      )))

;;; check-parameters
;;; given the instance parameters and the class-fields checks if the
;;; parameter is present in class-fields and the value type is valid
(defun check-parameters (inst-parameters class-fields)
  (every #'(lambda (parameter)
             (every #'(lambda (class-field)
                        (if (equal (first parameter) (first class-field))
                            (if (not (equal (third class-field) T))
                                (if (is-class (third class-field))
                                    (if (is-instance
                                         (second parameter)
                                         (third class-field))
                                        T
                                        NIL)
                                    (if (typep
                                         (second parameter)
                                         (third class-field))
                                        T
                                        (error "make-parameters:
value \"~A\" for field ~A is not of type ~A"  
                                               (second parameter)
                                               (first parameter)
                                               (third class-field))))
                                T)
                            T))
                    class-fields))
         inst-parameters))


;;; make-parameters
;;; checks if the every parameter is present in the class and if the
;;; type of the value is correct
(defun make-parameters (parameters class-name)
  (if (null parameters)
      NIL
      (let
          ((formatted-par (assoc-list-format parameters))
           (all-class-fields (get-class-fields class-name)))
        (mapcar #'(lambda (parameter)
                    (if (not (some #'(lambda (class-field)
                                       (equal
                                        (first parameter)
                                        (first class-field)))
                                   all-class-fields))
                        (error "make-parameters: field \"~A\" doesn't
belong to class \"~A\"" (first parameter) class-name)))
                formatted-par)

        (if (check-parameters formatted-par all-class-fields)
            formatted-par)
        )))

;;; make
;;; returns the code that represent the instance of a class
(defun make (class-name &rest parameters)
  (if (not (is-class class-name))
      (error "make: ~A is not a class" class-name))
  (let 
      ((inst-par (make-parameters parameters class-name)))
    (append  (list 'oolinst class-name) inst-par)
    ))

;;; get-superclass
;;; given a class name, returns a list containing the parents of the class
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
;;; given a list, returns T if represent an instance
;;; given a list and a class-name, returns T if the list represent an
;;; instance of class-name or class-name is a superclass of the instance
(defun is-instance (instance &optional (class-name T))
  (let ((oolinst (first instance))
        (inst-class (second instance)))
    (if (null (cond
                ((not (equal oolinst 'oolinst))
                 (error "is-instance: ~A doesn't define an instance"
                        oolinst))
                ((not (is-class inst-class))
                 (error "is-instance: ~A is not a class" inst-class))
                ((and (not (equal class-name T))
                      (not (member class-name (get-superclass inst-class)))
                      (not (equal inst-class class-name)))
                 (error "is-instance: ~A is not a class or a superclass of ~A" 
                        class-name inst-class))))
        T)))

;;; field
;;; given an instance and a field name, returns the value associated
;;; to field-name in the given instance
(defun field (instance field-name)
  (let* ((class-name (second instance))
         (all-fields (get-class-fields class-name))
         (inst-parameters (cdr (cdr instance)))
         (inst-result
           (first
            (remove-if #'null
                       (mapcar #'(lambda (par)
                                   (if (equal field-name (first par))
                                       par))
                               inst-parameters)))))
    (cond 
      ((not (some #'(lambda (class-field) 
                      (equal field-name (first class-field))
                      ) all-fields))
       (error "field: ~A doesn't belong to ~A's fields" 
              field-name class-name))
      )
    (if (null inst-result) 
        (second
         (first
          (remove-if #'null
                     (mapcar #'(lambda (par)
                                 (if (equal field-name (first par))
                                     par))
                             all-fields))))
        (second inst-result))
    )
  )

;;; field*
;;; given an instance and a list of field names, extracts the value
;;; from the instance by going through a chain of attributes 
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

;;; end of file - ool-lisp
