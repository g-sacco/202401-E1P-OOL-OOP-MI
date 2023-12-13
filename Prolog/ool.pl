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

% is_list_of_parts(+List)\1
% a part can be:
% 1) field(<field-name>, <value>)
% 2) field(<field-name>, <value>, <type>)
% 3) method(<method-name>, <arg-list>, <form>)
is_list_of_parts([]).
is_list_of_parts([Part | Parts]) :- % 1)
    same_functor(field(_, _), Part, 2),
    is_list_of_parts(Parts).
is_list_of_parts([Part | Parts]) :- % 2)
    same_functor(field(_, _, _), Part, 3),
    is_list_of_parts(Parts).
is_list_of_parts([Part | Parts]) :- % 3)
    same_functor(method(_, _, _), Part, 3),
    is_list_of_parts(Parts).

% assert_class(Class+, )
assert_class(Class_name, Parents, Parts) :-
    %HACK: What should I do if class with "Class_name" already exist?
    \+ is_class(Class_name), % test if class already exist
    Class =.. [class, Class_name, Parents, Parts],
    assertz(Class).

% def_class\2
def_class(Class_name, Parents) :-
    atom(Class_name),

    is_list(Parents),
    is_list_of_classes(Parents),

    assert_class(Class_name, Parents, []).

% def_class\3
def_class(Class_name, Parents, Parts) :-
    atom(Class_name),

    is_list(Parents),
    is_list_of_classes(Parents),

    is_list(Parts),
    is_list_of_parts(Parts),

    assert_class(Class_name, Parents, Parts).


%TBD:
%FIXME:
%HACK:

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
