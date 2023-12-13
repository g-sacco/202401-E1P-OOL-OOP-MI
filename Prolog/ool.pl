%%%  -*- Mode: Prolog -*-

%%% file: ool.pl

% is_class\1
% checks if the class exist
is_class(Class_name) :-
    class(Class_name, _, _).


% field\2 field-name è atomo
field(Field_name, Value) :-
    atom(Field_name).

% field\3
% checks if Type is a class
field(Field_name, Value, Type) :-
    atom(Field_name),
    is_class(Type).

% def_class\2
def_class(Class_name, Parents) :-
    atom(Class_name),
    is_list(Parents),
    assert(class(Class_name, Parents)).

% def_class\3
def_class(Class_name, Parents, Parts) :-
    atom(Class_name),
    is_list(Parents),
    is_list(Parts),
    assert(class(Class_name, Parents, Parts)).

%%% end of file - ool.pl
