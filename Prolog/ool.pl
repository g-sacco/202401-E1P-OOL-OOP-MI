%%%  -*- Mode: Prolog -*-

%%% file: ool.pl

:- dynamic class/3.

% is_class\1
% checks if the class exist
is_class(Class_name) :-
    class(Class_name, _, _).

% is_list_of_Classes(+List)\1
% checks if every element of a list is atomic
is_list_of_classes([]).
is_list_of_classes([X | Xs]) :-
    atom(X),
    is_class(X),
    is_list_of_classes(Xs).

% field(+Field_name, +Value)\2
field(Field_name, _) :-
    atom(Field_name).
% field(+Field_name, +Value, +Type)\3
field(Field_name, Value, Type) :-
    atom(Field_name),
    % HACK: Is a var() considered a Term?
    % e.g. field(age, AGE, var). is this ok?
    Test_type =.. [Type, Value],
    Test_type.  % Type(Value)
% method(+Method_name, +Arglist, +Form)\3
method(Method_name, Arglist, Form) :-
    atom(Method_name),
    is_list(Arglist),
    callable(Form).

% is_list_of_parts(+List)\1
is_list_of_parts([]).
is_list_of_parts([Part | Parts]) :- % 1)
    Part,
    is_list_of_parts(Parts).

% assert_class(Class+, )
assert_class(Class_name, Parents, Parts) :-
    % HACK: What should I do if class with "Class_name" already exist? aggiorna la variabile
    % TODO: Update the class if the class already exist
    \+ is_class(Class_name), % test if class already exist
    Class =.. [class, Class_name, Parents, Parts],
    assertz(Class).
assert_class(Class_name, Parents, Parts) :-
    is_class(Class_name),
    Class =.. [class, Class_name, _, _],
    retractall(Class),
    assert_class(Class_name, Parents, Parts).

% def_class\2
def_class(Class_name, Parents) :-
    def_class(Class_name, Parents, []).
% def_class\3
def_class(Class_name, Parents, Parts) :-
    atom(Class_name),

    is_list(Parents),
    is_list_of_classes(Parents),

    is_list(Parts),
    is_list_of_parts(Parts),

    assert_class(Class_name, Parents, Parts).

%%% -------- MAKE ---------------



% make(+Instance_name, +Class_name, +Fields)
%%% Instance_name is an atom()
make(Instance_name, Class_name) :-
    make(Instance_name, Class_name, []).

%%% TODO: create instance(Instance_name, )
make(Instance_name, Class_name, Fields) :-
    atom(Instance_name),
    is_class(Class_name),
    is_list(Fields),
    assertz(instance(Instance_name, Fields)).



%%% Instance_name is a var()
%%% TODO: make(Instance_name, Class_name, Fields) :- var(Instance_name).
%%% Instance_name is a term
%%%% TODO: make(Instance_name, Class_name, Fields) :-



% TODO:
% FIXME:
% HACK:

%Example
/*
class(person, [],
          [ field(name, "Eve"),
            field(age, 21, integer)]).
class(student, [person],
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
