:- set_prolog_flag(encoding, utf8).
:- ensure_loaded('family_tree.pl').

print_title(Title) :-
    format('~n~w~n----------------------------------------~n', [Title]).

print_pairs_or_none(Goal, X, Y) :-
    (   findall(X-Y, Goal, L), L \= []
    ->  forall(member(A-B, L), format('~w — ~w~n', [A,B]))
    ;   format('(нет решений)~n', [])
    ).

print_single_or_none(Goal, V) :-
    (   call(Goal) -> format('~w~n', [V])
    ;   format('(нет решений)~n', [])
    ).

print_bool(Goal) :-
    (   call(Goal) -> format('Да~n', [])
    ;   format('Нет~n', [])
    ).

print_value_or_none(Goal, V) :-
    (   call(Goal) -> format('~w~n', [V])
    ;   format('(нет решений)~n', [])
    ).

run_sections :-
    format('==== ЗАПРОСЫ К СЕМЕЙНОМУ ДЕРЕВУ ====~n', []),

    % 1. Браки в 1978
    print_title('1. Браки в 1978'),
    print_pairs_or_none(married_in_year(X,Y,1978), X, Y),

    % 2. Супруг(а) Дмитрия в 2005
    print_title('2. Супруг(а) Дмитрия в 2005'),
    print_single_or_none(married_in_year(sadovoy_dmitriy, Y, 2005), Y),

    % 3. Разводы в 2009
    print_title('3. Разводы в 2009'),
    print_pairs_or_none(divorced_in_year(X,Y,2009), X, Y),

    % 4. Отец Георгия в 2007
    print_title('4. Отец Георгия в 2007'),
    print_single_or_none(father_in_year(F, faktorovich_georgiy, 2007), F),

    % 5. Мать Григория в 2016
    print_title('5. Мать Григория в 2016'),
    print_single_or_none(mother_in_year(M, sadovoy_grigoriy, 2016), M),

    % 6. Вдовцы/вдовы в 2024
    print_title('6. Вдовцы/вдовы в 2024'),
    (   findall(P, widowed_in_year(P, 2024), L), L \= []
    ->  forall(member(P, L), format('~w~n', [P]))
    ;   format('(нет решений)~n', [])
    ),

    % 7. Марина и Владимир в браке в 2016?
    print_title('7. Марина и Владимир в браке в 2016?'),
    print_bool(married_in_year(sadovaya_marina, lyutikov_vladimir, 2016)),

    % 8. Аркадий жив в 1985?
    print_title('8. Аркадий жив в 1985?'),
    print_bool(alive_in_year(sadovoy_arkadiy, 1985)),

    % 9. Возраст Александра младшего в 2020
    print_title('9. Возраст Александра младшего в 2020'),
    print_value_or_none(age_in_year(sadovoy_aleksandr_ml, 2020, A), A),

    % 10. Кузены Григория в 2015
    print_title('10. Кузены Григория в 2015'),
    (   findall(C, cousin_in_year(sadovoy_grigoriy, C, 2015), L2), L2 \= []
    ->  forall(member(C, L2), format('~w~n', [C]))
    ;   format('(нет решений)~n', [])
    ),

    format('~n==== ГОТОВО ====~n', []).

% Удобная точка входа для ручного запуска
run :- run_sections.
