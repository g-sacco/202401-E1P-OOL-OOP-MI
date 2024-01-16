Sacco Giacomo 899927

Funzioni progetto Common Lisp


parents-check
checks if parents is a list of classes

find-class-field
given a class name and a field name, search the field name in the
class and if it is found is returned otherwise return NIL

field-check
Checks a given field (field-name value field-type), if
everything is fine returns NIL otherwise gives an error

append-list
given a list of lists appends each element in a single list

get-class-methods
given a class name, it returns a list containing all of his methods

get-method
given an instance and a method name, it returns the method
associated to the instance with method-name as a name

rewrite-method-code
given method-name and method-spec (arglist + form), it returns a
lambda function with the "this" argument added

process-method
given method-name and method-spec (arglist + form), it adds the
function definition of method-name and binds to it a lambda
function representing the given method, than it evaluates the
rewritten method

method-check
checks if the given method is valid, if it's not returns an error

parts-check
checks if the given part is valid, than based on part-type
(methods or fields) launches field-check and method-check on each
element using mapcar

format-field-type
given a list of parts (methods and fields) select the fields list
and adds T to the fields without a specified type, than returns
the updated fields list

format-method
given a list of parts (methods and fields) select the methods
list, than runs "process-method" on each method and returns an
associative list containing the method-name and the related
function returned by "process-method"

def-class
check if class-name, parents and part are correct, than adds the
class to centralized location: *classes-specs*


is-class
if the given class-name represents a defined class, returns T

assoc-list-format
format a list of elmentsts, associate them two by two
(1 2 3 4) -> ((1 2) (3 4))

get-class-fields
return a list containig all the fields of a class including the
inherited fields.

check-parameters
given the instance parameters and the class-fields checks if the
parameter is present in class-fields and the value type is valid

make-parameters
checks if the every parameter is present in the class and if the
type of the value is correct

make
returns the code that represent the instance of a class

get-superclass
given a class name, returns a list containing the parents of the class

is-instance
given a list, returns T if represent an instance
given a list and a class-name, returns T if the list represent an
instance of class-name or class-name is a superclass of the instance

field
given an instance and a field name, returns the value associated
to field-name in the given instance

field*
given an instance and a list of field names, extracts the value
from the instance by going through a chain of attributes 
