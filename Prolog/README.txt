Sacco Giacomo 899927

Predicati progetto PROLOG

is_class\1
checks if the class exist

is_list_of_Classes\2
checks if every element of a list is atomic and is different from the
passed class 

is_list_of_parts\1
checks if the given list is a list of fields and methods

assert_class_parents()\2
given the class-name and a list of parents links class_name and
each parent using the predicate "superclass"

assert_class_parts()\2
asserts fields as "class_field()" and methods as "class_method()"

assert_class\3
given a class name, parents, fields and methods (parts), assert a
new class using the predicate "class()\3". If class already exist
gives an error.

def_class\3
given a class name, parents, fields and methods (parts), launches
the procedures to define a new class

instance_field_doesnt_exist\1
return false if field_name has already been asserted

assert_instance_fields\3
asserts the given list of fields using the predicate
"instance_field", using the given instance values or the default
class values. In case Type is present the custom value is checked

assert_all_instance_fields\3
finds all the fields related to the instance's class and use
"assert_instance_fields" to assert them all

get_all_parents_list\2
recursive function to find all the parents of a class starting
from the directly related parents

get_all_parents()\2
given a class name returns a list containing all of his parents
and himself

substitute_this_chars\3
give a list of characters resturns a list with the occurrences of
[t, h, i, s] substituted by "Sub" (which contains the instance name
divided in characters)

substitute_this\3
substitutes the occcurences of "this" in the given method with the
value of "Substitute" which is the name of the instance

assert_instance_method\2
given a list of methods use "substitute_this" to personalize the
method for the given instance than assert each method

assert_instance_parents_methods\2
given an instance name and list of classes, finds all the methods
related to the first class and asserts them, than finds all the
parents and make a recursive call with them, in the end make a
recursive call with the Tail of the list

assert_instance_methods\2
given an instance name and a class name finds all the methods of
class name and call method to assert them in order to be used with
the instance, than call a method to recursively assert all the
parents methods

assert_instance\3
if Instance_name doesn't represent an instance yet, asserts the
instance using the predicate "instance_()" linking the instance
name to the class name. then launches the procedures to assert all
the remaining parts

make\3
if "Instance_name" is an atom creates a new instance named
"Instance_name". if "Instance_name" is a variable unifies with the
predicate representing the instance

is_instance()
given an instance name, returns true if the instance exist
given an instance name and a class, returns true if the instance
is an instance of the class or the class is a superclass of the
instance's class

inst\2
given an instance name returns "Instance" which is a predicate
representing the instance (inst_name, class, [key = value, ...])

field\3
given an instance name and a field name, returns the value
associated to field in the specified instance

fieldx\3
given an instance name and a list of field names, extracts the value
from the instance by going through the chain fields given in the
list and returns the last value
