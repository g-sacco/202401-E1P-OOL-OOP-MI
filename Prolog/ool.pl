%%%% Sacco Giacomo 899927

%%%  -*- Mode: Prolog -*-

%%% file: ool.pl

:- dynamic class/3.
:- dynamic class_field/3.
:- dynamic class_field/4.
:- dynamic class_method/4.
:- dynamic instance_/2.
:- dynamic superclass/2.
:- dynamic instance_field/4.

%%% is_class\1
%%% checks if the class exist
is_class(Class_name) :-
    atom(Class_name),
    class(Class_name, _, _).

%%% is_list_of_Classes\1
%%% checks if every element of a list is atomic
is_list_of_classes([], _).
is_list_of_classes([X | Xs], Curr_class) :-
    X \= Curr_class,
    atom(X),
    is_class(X),
    is_list_of_classes(Xs, Curr_class).

%%% is_list_of_parts\1
%%% checks if the given list is a list of fields and methods
is_list_of_parts([]).
is_list_of_parts([field(Field_name, _Value) | Parts]) :-
    atom(Field_name),
    is_list_of_parts(Parts).
is_list_of_parts([field(Field_name, Value, Type) | Parts]) :-
    atom(Field_name),
    Test_type =.. [Type, Value],
    Test_type,  % Type(Value)
    is_list_of_parts(Parts).
is_list_of_parts([method(Method_name, Arglist, Form) | Parts]) :-
    atom(Method_name),
    is_list(Arglist),
    callable(Form),
    is_list_of_parts(Parts).

%%% assert_class_parents()\2
%%% given the class-name and a list of parents links class_name and
%%% each parent using the predicate "superclass"
assert_class_parents(_Class_name, []).
assert_class_parents(Class_name, [Parent | Tail]) :-
    Superclass =.. [superclass, Class_name, Parent],
    assertz(Superclass), % superclass(CN, PN)
    assert_class_parents(Class_name, Tail).


%%% assert_class_parts()\2
%%% asserts fields as "class_field()" and methods as "class_method()"
assert_class_parts(_Class_name, []).
assert_class_parts(Class_name, [field(Field_name, Value) | Tail]) :-
    Field =.. [class_field, Class_name,  Field_name, Value],
    assertz(Field),
    assert_class_parts(Class_name, Tail).
assert_class_parts(Class_name, [field(Field_name, Value, Type) | Tail]) :-
    Field =.. [class_field, Class_name, Field_name, Value, Type],
    assertz(Field),
    assert_class_parts(Class_name, Tail).
assert_class_parts(Class_name, [method(Method_name, Arguments, Form) | Tail]) :-
    Class_method =.. [class_method, Class_name, Method_name, Arguments, Form],
    assertz(Class_method),
    assert_class_parts(Class_name, Tail).

%%% assert_class\3
%%% given a class name, parents, fields and methods (parts), assert a
%%% new class using the predicate "class()\3". If class already exist
%%% gives an error.
assert_class(Class_name, Parents, Parts) :-
    \+ is_class(Class_name), % test if class already exist
    Class =.. [class, Class_name, Parents, Parts],
    assertz(Class),
    assert_class_parents(Class_name, Parents),
    assert_class_parts(Class_name, Parts).
assert_class(Class_name, _Parents, _Parts) :-
    is_class(Class_name),
    write("Error: assert_class: the class \""),
    write(Class_name),
    writeln("\" already exists"),
    fail.

%%% def_class\3
%%% given a class name, parents, fields and methods (parts), launches
%%% the procedures to define a new class
def_class(Class_name, Parents) :-
    def_class(Class_name, Parents, []).
def_class(Class_name, Parents, Parts) :-
    atom(Class_name),

    is_list(Parents),
    is_list_of_classes(Parents, Class_name),

    is_list(Parts),
    is_list_of_parts(Parts),

    assert_class(Class_name, Parents, Parts).


%%% assert_instance_fields\3
%%% asserts the given list of fields using the predicate
%%% "instance_field", using the given instance values or the default
%%% class values. In case Type is present the custom value is checked
assert_instance_fields(_Instance_name, [], _Instance_values).
%%% class_field
%%% use CUSTOM field value
assert_instance_fields(Instance_name,
                       [class_field(_, Key, _Val) | Tail],
                       Instance_values) :-
    member(Key = Value, Instance_values),
    Instance_field =.. [instance_field, Instance_name, Key, Value],
    assertz(Instance_field),
    assert_instance_fields(Instance_name,  Tail, Instance_values).
%%% use DEFAULT field_value
assert_instance_fields(Instance_name,
                       [class_field(_, Key, Value) | Tail],
                       Instance_values) :-
    \+ member(Key = _Val, Instance_values),
    Instance_field =.. [instance_field, Instance_name, Key, Value],
    assertz(Instance_field),
    assert_instance_fields(Instance_name,  Tail, Instance_values).
%%% class_field with TYPE
%%% use CUSTOM field value
assert_instance_fields(Instance_name,
                       [class_field(_, Key, _Val, Type) | Tail],
                       Instance_values) :-
    member(Key = Value, Instance_values),
    Instance_field =.. [instance_field, Instance_name, Key, Value, Type],
    Type_test =.. [Type, Value],
    Type_test,
    assertz(Instance_field),
    assert_instance_fields(Instance_name,  Tail, Instance_values).
%%% use DEFAULT field_value
assert_instance_fields(Instance_name,
                       [class_field(_, Key, Value, _Type) | Tail],
                       Instance_values) :-
    \+ member(Key = _Val, Instance_values),
    Instance_field =.. [instance_field, Instance_name, Key, Value],
    assertz(Instance_field),
    assert_instance_fields(Instance_name,  Tail, Instance_values).


%%% assert_all_instance_fields\3
%%% finds all the fields related to the instance's class and use
%%% "assert_instance_fields" to assert them all
assert_all_instance_fields(_Instance_name, [], _Values).
assert_all_instance_fields(Instance_name,
                               [Class_name | Tail],
                               Instance_values) :-
    findall(class_field(_, Key, Val),
            class_field(Class_name, Key, Val),
            Class_fields_notype),
    findall(class_field(_, Key, Val, Type),
            class_field(Class_name, Key, Val, Type),
            Class_fields_type),
    append(Class_fields_notype, Class_fields_type, Class_fields),
    assert_instance_fields(Instance_name, Class_fields, Instance_values),
    assert_all_instance_fields(Instance_name, Tail, Instance_values).

%%% get_all_parents_list\2
%%% recursive function to find all the parents of a class starting
%%% from the directly related parents
get_all_parents_list([], []).
get_all_parents_list([Class | Tail], Result) :-
    get_all_parents_list(Tail, All_parents),
    atom(Class),
    findall(Parent,
            superclass(Class, Parent),
            Parents),
    append(Parents, All_parents, X),
    append([Class], X, Result).

%%% get_all_parents()\2
%%% given a class name returns a list containing all of his parents and himself
get_all_parents(Class_name, All_parents) :-
    atom(Class_name),
    findall(Parent,
            superclass(Class_name, Parent),
            Parents),
        get_all_parents_list(Parents, All_parents).

%%% substitute_this_chars\3
%%% give a list of characters resturns a list with the occurrences of
%%% [t, h, i, s] substituted by "Sub" (which contains the instance name
%%% divided in characters)
substitute_this_chars([], _Sub, []).
substitute_this_chars([t, h, i, s | Tail], Sub, [Sub | Res]) :-
    substitute_this_chars(Tail, Sub, Res),
    !.
substitute_this_chars([Head | Tail], Sub, [Head | Res]) :-
    substitute_this_chars(Tail, Sub, Res).

%%% substitute_this\3
%%% substitutes the occcurences of "this" in the given method with the
%%% value of "Substitute" which is the name of the instance
substitute_this(Term_old, Substitute, Result) :-
    term_string(Term_old, String_old),
    string_chars(String_old, Chars_old),
    string_chars(Substitute, Sub_chars),
    substitute_this_chars(Chars_old, Sub_chars, Chars_new),
    flatten(Chars_new, Flat_chars_new),
    string_chars(Flat_string_new, Flat_chars_new),
    term_string(Result, Flat_string_new).

%%% assert_instance_method\2
%%% given a list of methods use "substitute_this" to personalize the
%%% method for the given instance than assert each method 
assert_instance_method(_Instance_name, []).
assert_instance_method(Instance_name,
                       [class_method(_Class_name,
                                     Method_name,
                                     Args,
                                     Form) | Tail]) :-
    append([[Method_name], [Instance_name], Args], Predicate),
    Method =.. Predicate,
    substitute_this(Form, Instance_name, New_form),
    assertz(Method :- New_form),
    assert_instance_method(Instance_name, Tail).

%%% assert_instance_parents_methods\2
%%% given an instance name and list of classes, finds all the methods
%%% related to the first class and asserts them, than finds all the
%%% parents and make a recursive call with them, in the end make a
%%% recursive call with the Tail of the list
assert_instance_parents_methods(_Instance_name, []).
assert_instance_parents_methods(Instance_name, [Class_name | Tail]) :-
     findall(class_method(Class_name, Method_name, Arguments, Form),
            class_method(Class_name, Method_name, Arguments, Form),
            Methods),
     findall(Parent,
	     superclass(Class_name, Parent),
	     Parents),
     assert_instance_method(Instance_name, Methods),
     assert_instance_parents_methods(Instance_name, Parents),
     assert_instance_parents_methods(Instance_name, Tail).

%%% assert_instance_methods\2
%%% given an instance name and a class name finds all the methods of
%%% class name and call method to assert them in order to be used with
%%% the instance, than call a method to recursively assert all the
%%% parents methods
assert_instance_methods(Instance_name, Class_name) :-
    findall(class_method(Class_name, Method_name, Arguments, Form),
            class_method(Class_name, Method_name, Arguments, Form),
            Methods),
    findall(Parent,
	    superclass(Class_name, Parent),
	    Parents),
    %%%%%%%%%%%%%%%%%%%%%%% TODO: inherit all parents methods, if duplicate use the nearest method
    assert_instance_method(Instance_name, Methods),
    assert_instance_parents_methods(Instance_name, Parents).

%%% assert_instance()\3
%%% if Instance_name doesn't represent an instance yet, asserts the
%%% instance using the predicate "instance_()" linking the instance
%%% name to the class name. then launches the procedures to assert all
%%% the remaining parts 
assert_instance(Instance_name, Class_name, Instance_values) :-
    \+ is_instance(Instance_name),
    assertz(instance_(Instance_name, Class_name)),
    get_all_parents(Class_name, Parent_classes),
    append([Class_name], Parent_classes, Related_classes),
    assert_all_instance_fields(Instance_name,
                                   Related_classes,
                                   Instance_values),
    assert_instance_methods(Instance_name, Class_name).

%%% make(+Instance_name, +Class_name, +Fields)
%%% if "Instance_name" is an atom creates a new instance named
%%% "Instance_name". if "Instance_name" is a variable unifies with the
%%% predicate representing the instance 
make(Instance_name, Class_name) :-
    make(Instance_name, Class_name, []).
make(Instance_name, Class_name, Fields) :-
    atom(Instance_name),
    is_class(Class_name),
    is_list(Fields),
    assert_instance(Instance_name, Class_name, Fields).
make(Instance_name, Class_name, Fields) :-
    var(Instance_name),
    is_class(Class_name),
    is_list(Fields),
    Instance_name =.. [instance_, any, Class_name].

%%% is_instance()
%%% given an instance name, returns true if the instance exist
%%% given an instance name and a class, returns true if the instance
%%% is an instance of the class or the class is a superclass of the
%%% instance's class
is_instance(Instance_name) :-
    instance_(Instance_name, _Class_name).
is_instance(Instance_name, Superclass_name) :-
    instance_(Instance_name, Class_name),
    get_all_parents(Class_name, Parents),
    append([Class_name], Parents, Classes),
    member(Superclass_name, Classes).

%%% inst\2
%%% given an instance name returns "Instance" which is a predicate
%%% representing the instance (inst_name, class, [key = value, ...])
inst(Instance_name, Instance) :-
    instance_(Instance_name, Class_name),
    findall(Key = Value,
            instance_field(Instance_name, Key, Value),
            Fields_notype),
    findall(Key = Value,
            instance_field(Instance_name, Key, Value, _Type),
            Fields_type),
    append(Fields_notype, Fields_type, Fields),
    Instance =.. [instance_, Instance_name, Class_name, Fields].

%%% field()\3
%%% given an instance name and a field name, returns the value
%%% associated to field in the specified instance
field(Instance_name, Field_name, Result) :-
    instance_field(Instance_name, Field_name, Result).
field(Instance_name, Field_name, Result) :-
    instance_field(Instance_name, Field_name, Result, _).

%%% fieldx()\3
%%% given an instance name and a list of field names, extracts the value
%%% from the instance by going through the chain fields given in the
%%% list and returns the last value
fieldx(Result, [], Result).
fieldx(Instance_name, [Field_name | Tail], Result) :-
    is_instance(Instance_name),
    field(Instance_name, Field_name, Value),
    fieldx(Value, Tail, Result).

%%% end of file - ool.pl
