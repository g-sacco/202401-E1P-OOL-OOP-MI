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
%%% use CUSTOM field value
assert_instance_fields(Instance_name, [Class_field | Tail], Instance_values) :-
    %%% TODO: assert "instance_field(Instance_name, Field_name, Value)"
    %%% parsing each class field and looking for instance values
    arg(2, Class_field, Key),
    member(Key = Value, Instance_values),
    Instance_field =.. [instance_field, Instance_name, Key, Value],
    assertz(Instance_field),
    assert_instance_fields(Instance_name,  Tail, Instance_values).
%%% use DEFAULT field_value
assert_instance_fields(Instance_name, [Class_field | Tail], Instance_values) :-
    arg(2, Class_field, Key),
    \+ member(Key = _Val, Instance_values),
    arg(3, Class_field, Value),
    Instance_field =.. [instance_field, Instance_name, Key, Value],
    assertz(Instance_field),
    assert_instance_fields(Instance_name,  Tail, Instance_values).

%%% assert_instance()
assert_instance(Instance_name, Class_name, Fields) :-
    assertz(instance(Instance_name, Class_name)),
    findall(class_field(_, X, Y),
            class_field(Class_name, X, Y),
            Class_fields),
    assert_instance_fields(Instance_name, Class_fields, Fields).



% make(+Instance_name, +Class_name, +Fields)
%%% Instance_name is an atom()
make(Instance_name, Class_name) :-
    make(Instance_name, Class_name, []).

%%% TODO: create instance(Instance_name, )
make(Instance_name, Class_name, Fields) :-
    atom(Instance_name),
    is_class(Class_name),
    is_list(Fields),
    %%% TODO: check  if fields are present in class
    %%%       inherit all the class fields
    assert_instance(Instance_name, Class_name, Fields).
    %assertz(instance(Class_name, Instance_name, Fields))


%%% TODO: inst\2
%%% build instance(inst_name, class, [key = value, ...])
%%% given inst_name



%%% Instance_name is a var()
%%% TODO: make(Instance_name, Class_name, Fields) :- var(Instance_name).
%%% Instance_name is a term
%%% TODO: make(Instance_name, Class_name, Fields) :-



% TODO:
% FIXME:
% HACK:

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
*/
%%% end of file - ool.pl
