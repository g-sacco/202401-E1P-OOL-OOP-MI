%%%  -*- Mode: Prolog -*-

%%% file: ool.pl

:- dynamic class/3.
:- dynamic class_field/3.
:- dynamic class_field/4
:- dynamic class_method/4.

% is_class\1
% checks if the class exist
is_class(Class_name) :-
    atom(Class_name),
    class(Class_name, _, _).

% is_list_of_Classes(+List)\1
% checks if every element of a list is atomic
is_list_of_classes([], _).
is_list_of_classes([X | Xs], Curr_class) :-
    X \= Curr_class,
    atom(X),
    is_class(X),
    is_list_of_classes(Xs, Curr_class).

% is_list_of_parts(+List)\1
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
assert_class_parents(_Class_name, []).
assert_class_parents(Class_name, [Parent | Tail]) :-
    Superclass =.. [superclass, Class_name, Parent],
    assertz(Superclass), % superclass(CN, PN)
    assert_class_parents(Class_name, Tail).

%%% assert_class_parts()\2
assert_class_parts(_Class_name, []).
%%% assert class_field\2
assert_class_parts(Class_name, [Part | Tail]) :-
    functor(Part, field, 2),
    arg(1, Part, Field_name),
    arg(2, Part, Value),
    Field =.. [class_field, Class_name,  Field_name, Value],
    assertz(Field),
    assert_class_parts(Class_name, Tail).
%%% assert_class_field\2
assert_class_parts(Class_name, [Part | Tail]) :-
    functor(Part, field, 3),
    arg(1, Part, Field_name),
    arg(2, Part, Value),
    arg(3, Part, Type),
    Field =.. [class_field, Class_name, Field_name, Value, Type],
    assertz(Field),
    assert_class_parts(Class_name, Tail).
%%% assert_class_method\3
assert_class_parts(Class_name, [Part | Tail]) :-
    functor(Part, method, 3),
    arg(1, Part, Method_name),
    arg(2, Part, Arguments),
    arg(3, Part, Form),
    Method =.. [class_method, Class_name, Method_name, Arguments, Form],
    assertz(Method),
    assert_class_parts(Class_name, Tail).


% assert_class\3
assert_class(Class_name, Parents, Parts) :-
    % TODO: print an error message when a class already exist
    \+ is_class(Class_name), % test if class already exist
    Class =.. [class, Class_name, Parents, Parts],
    assertz(Class),
    assert_class_parents(Class_name, Parents),
    assert_class_parts(Class_name, Parts).

% def_class\2
def_class(Class_name, Parents) :-
    def_class(Class_name, Parents, []).
% def_class\3
def_class(Class_name, Parents, Parts) :-
    atom(Class_name),

    is_list(Parents),
    is_list_of_classes(Parents, Class_name),

    is_list(Parts),
    is_list_of_parts(Parts),

    assert_class(Class_name, Parents, Parts).

%%% -------- MAKE ---------------

%%% assert_instance_fields\3
assert_instance_fields(_Instance_name, [], _Instance_values).
%%% class_field
%%% use CUSTOM field value
assert_instance_fields(Instance_name, [class_field(_, Key, _Val) | Tail], Instance_values) :-
%    arg(2, Class_field, Key),
    member(Key = Value, Instance_values),
    Instance_field =.. [instance_field, Instance_name, Key, Value],
    assertz(Instance_field),
    assert_instance_fields(Instance_name,  Tail, Instance_values).
%%% use DEFAULT field_value
assert_instance_fields(Instance_name, [class_field(_, Key, Value) | Tail], Instance_values) :-
    \+ member(Key = _Val, Instance_values),
    Instance_field =.. [instance_field, Instance_name, Key, Value],
    assertz(Instance_field),
    assert_instance_fields(Instance_name,  Tail, Instance_values).

%%% class_field with TYPE
%%% use CUSTOM field value
assert_instance_fields(Instance_name, [class_field(_, Key, _Val, Type) | Tail], Instance_values) :-
    member(Key = Value, Instance_values),
    Instance_field =.. [instance_field, Instance_name, Key, Value, Type],
    Type_test =.. [Type, Value],
    Type_test,
    assertz(Instance_field),
    assert_instance_fields(Instance_name,  Tail, Instance_values).
%%% use DEFAULT field_value
assert_instance_fields(Instance_name, [class_field(_, Key, Value, _Type) | Tail], Instance_values) :-
    \+ member(Key = _Val, Instance_values),
    Instance_field =.. [instance_field, Instance_name, Key, Value],
    assertz(Instance_field),
    assert_instance_fields(Instance_name,  Tail, Instance_values).


%%% assert_instance_parents_fields\3
assert_instance_parents_fields(_Instance_name, [], _Values).
assert_instance_parents_fields(Instance_name, [Class_name | Tail], Instance_values) :-
    findall(class_field(_, X, Y),
            class_field(Class_name, X, Y),
            Class_fields),
    assert_instance_fields(Instance_name, Class_fields, Instance_values),
    assert_instance_parents_fields(Instance_name, Tail, Instance_values).

%%% get_all_parents_list\2
%%% recursice function to find all the parents of a class
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
%%% given a class name returns a list containing  all his parents and himself
get_all_parents(Class_name, All_parents) :-
    atom(Class_name),
    findall(Parent,
            superclass(Class_name, Parent),
            Parents),
        get_all_parents_list(Parents, All_parents).

%%% assert_instance()
assert_instance(Instance_name, Class_name, Instance_values) :-
    \+ is_instance(Instance_name),
    assertz(instance(Instance_name, Class_name)),
    get_all_parents(Class_name, Parent_classes),
    append([Class_name], Parent_classes, Related_classes),
    assert_instance_parents_fields(Instance_name, Related_classes, Instance_values).

% make(+Instance_name, +Class_name, +Fields)
%%% Instance_name is an atom()
make(Instance_name, Class_name) :-
    make(Instance_name, Class_name, []).

make(Instance_name, Class_name, Fields) :-
    atom(Instance_name),
    is_class(Class_name),
    is_list(Fields),
    assert_instance(Instance_name, Class_name, Fields).

%%% TODO: make v2
%%% TODO: make v3

%%% is_instance()
is_instance(Instance_name) :-
    instance(Instance_name, _Class_name).
is_instance(Instance_name, Superclass_name) :-
    instance(Instance_name, Class_name),
    get_all_parents(Class_name, Parents),
    member(Superclass_name, Parents).

%%% inst\2
%%% build instance(inst_name, class, [key = value, ...])
inst(Instance_name, Instance) :-
    instance(Instance_name, Class_name),
    findall(Key = Value,
            instance_field(Instance_name, Key, Value),
            Fields_notype),
    findall(Key = Value,
            instance_field(Instance_name, Key, Value, _Type),
            Fields_type),
    append(Fields_notype, Fields_type, Fields),
    Instance =.. [instance, Instance_name, Class_name, Fields].

%%% field()\3
field(Instance_name, Field_name, Result) :-
    instance_field(Instance_name, Field_name, Result).
field(Instance_name, Field_name, Result) :-
    instance_field(Instance_name, Field_name, Result, _).

%%% fieldx()\3
fieldx(Result, [], Result).
fieldx(Instance_name, [Field_name | Tail], Result) :-
    is_instance(Instance_name),
    field(Instance_name, Field_name, Value),
    fieldx(Value, Tail, Result).
%Example
/*
class(person, [],
          [ field(name, "Eve"),
            field(age, 21, integer)]).
def_class(student, [person],
          [ field(name, "Eva Lu Ator"),
            field(university, "Berkeley"),
            method(talk, [], (write("My name is "),
                              field(this, name, N),
                              writeln(N),
                              write("My age is "),
                              field(this, age, A),
                              writeln(A)))]).

def_class(planet, [], [field(name, terra)]).
def_class(continent, [planet], [field(name2, europa)]).
def_class(state, [continent], [field(name3, italia)]).
make(s1, state, [name1 = "Marte", name2 = "Avis", name3="site"]).
*/
%%% end of file - ool.pl
