:- set_prolog_flag(encoding, utf8).
:- discontiguous born/2.
:- discontiguous died/2.
:- discontiguous married/3.
:- discontiguous divorced/3.

% Первое колено
person(sadovoy_grigoriy, male).
person(faktorovich_aleksandra, female).
person(faktorovich_georgiy, male).
person(sadovoy_nikita, male).
person(sadovaya_olga, female).
person(sadovaya_natalya, female).
person(sadovaya_anna, female).
person(sadovoy_vadim, male).
person(sadovoy_ivan, male).
person(vazovskiy_mike, male).

% Второе колено
person(faktorovich_ilya, male).
person(lyutikova_elena, female).
person(lyutikov_vladimir, male).
person(sadovaya_marina, female).
person(sadovaya_irina, female).
person(kirilina_lyubov, female).
person(kirilin_vasiliy, male).
person(redis_yablokovich, male).
person(sadovaya_margarita, female).
person(sadovoy_dmitriy, male).
person(ubuntu_svetlana, female).
person(sadovoy_andrey, male).
person(shkafchik_agnes, female).

% Третье колено
person(kirilin_valeriy, male).
person(arhipova_lyubov, female).
person(arhipova_natalya, female).
person(sadovoy_valeriy, male).
person(sadovoy_aleksandr_ml, male).
person(sadovoy_arkadiy, male).
person(gandzhubas_olga, female).
person(mak_iona, female).

% Четвертое колено
person(sadovoy_aleksandr_st, male).
person(sinitsina_margarita, female).

/* ======================= BORN / DIED ======================= */
% Первое колено
born(sadovoy_grigoriy, 2004).
born(faktorovich_aleksandra, 2004).
born(faktorovich_georgiy, 2007).
born(sadovoy_nikita, 2002).
born(sadovaya_olga, 2002).
born(sadovaya_natalya, 2005).
born(sadovaya_anna, 2008).
born(sadovoy_vadim, 2007).
born(sadovoy_ivan, 2004).
born(vazovskiy_mike, 1999).

% Второе колено
born(faktorovich_ilya, 1985).
born(lyutikova_elena, 1984).
born(lyutikov_vladimir, 1974).  died(lyutikov_vladimir, 2017).
born(sadovaya_marina, 1985).
born(sadovaya_irina, 1980).
born(kirilina_lyubov, 1982).
born(kirilin_vasiliy, 1989).
born(redis_yablokovich, 1973).
born(sadovaya_margarita, 1980).
born(sadovoy_dmitriy, 1979).
born(ubuntu_svetlana, 1984).
born(sadovoy_andrey, 1989).
born(shkafchik_agnes, 1993).

% Третье колено
born(kirilin_valeriy, 1962).  died(kirilin_valeriy, 2024).
born(arhipova_lyubov, 1967).
born(arhipova_natalya, 1964).
born(sadovoy_valeriy, 1963).
born(sadovoy_aleksandr_ml, 1955).  died(sadovoy_aleksandr_ml, 2025).
born(sadovoy_arkadiy, 1965).  died(sadovoy_arkadiy, 1999).
born(gandzhubas_olga, 1961).
born(mak_iona, 1964).  died(mak_iona, 1994).

% Четвертое колено
born(sadovoy_aleksandr_st, 1936).  died(sadovoy_aleksandr_st, 1999).
born(sinitsina_margarita, 1932).  died(sinitsina_margarita, 2007).

/* ======================= MARRIAGE / DIVORCE ======================= */
married(sadovoy_aleksandr_st, sinitsina_margarita, 1948).

married(sadovoy_aleksandr_ml, gandzhubas_olga, 1976).

married(sadovoy_valeriy, arhipova_natalya, 1978).

married(arhipova_lyubov, kirilin_valeriy, 1980).

married(sadovoy_arkadiy, mak_iona, 1975).

married(sadovoy_andrey, shkafchik_agnes, 2002).

married(lyutikova_elena, faktorovich_ilya, 2003).

married(sadovaya_marina, lyutikov_vladimir, 2015).
divorced(sadovaya_marina, lyutikov_vladimir, 2016).

married(sadovoy_dmitriy, ubuntu_svetlana, 2001).
divorced(sadovoy_dmitriy, ubuntu_svetlana, 2009).

married(vazovskiy_mike, sadovoy_ivan, 2025).

/* ======================= ADOPTION / CHILDREN ======================= */
adopted_by(faktorovich_georgiy, faktorovich_ilya, lyutikova_elena, 2007).

biological_child_of(sadovoy_aleksandr_ml, sadovoy_aleksandr_st, sinitsina_margarita).
biological_child_of(sadovoy_valeriy,      sadovoy_aleksandr_st, sinitsina_margarita).

biological_child_of(sadovaya_irina,  sadovoy_valeriy, arhipova_natalya).
biological_child_of(sadovaya_marina, sadovoy_valeriy, arhipova_natalya).

biological_child_of(sadovoy_dmitriy,   sadovoy_aleksandr_ml, gandzhubas_olga).
biological_child_of(sadovaya_margarita, sadovoy_aleksandr_ml, gandzhubas_olga).

biological_child_of(sadovoy_andrey, sadovoy_arkadiy, mak_iona).

biological_child_of(sadovaya_olga,   sadovoy_dmitriy, ubuntu_svetlana).
biological_child_of(sadovaya_natalya, sadovoy_dmitriy, ubuntu_svetlana).
biological_child_of(sadovaya_anna,    sadovoy_dmitriy, ubuntu_svetlana).

biological_child_of(sadovoy_grigoriy, lyutikov_vladimir, sadovaya_marina).

biological_child_of(faktorovich_aleksandra, faktorovich_ilya, lyutikova_elena).

biological_child_of(sadovoy_nikita, redis_yablokovich, sadovaya_margarita).

/* ======================= RULES (как у тебя были) ======================= */
male(P)   :- person(P, male).
female(P) :- person(P, female).

alive(P) :- born(P,_), \+ died(P,_).

alive_in_year(P, Year) :-
    born(P, B),
    ( died(P, D) -> B =< Year, Year =< D
    ; B =< Year ).

age_in_year(P, Year, Age) :-
    born(P, B),
    ( died(P, D), Year > D -> Age is D - B
    ; Age is Year - B ).

adult_in_year(P, Year) :- age_in_year(P, Year, A), A >= 18.
minor_in_year(P, Year) :- age_in_year(P, Year, A), A < 18.

spouses(X, Y) :- married(X, Y, _).
spouses(X, Y) :- married(Y, X, _).

married_in_year(X, Y, Year) :-
    spouses(X, Y),
    (married(X, Y, S) ; married(Y, X, S)),
    S =< Year,
    ( (divorced(X, Y, E) ; divorced(Y, X, E)) -> Year =< E ; true ).

divorced_in_year(X, Y, Year) :-
    divorced(X, Y, Year) ; divorced(Y, X, Year).

currently_married(X, Y) :-
    spouses(X, Y),
    \+ divorced(X, Y, _),
    \+ divorced(Y, X, _).

single_in_year(P, Year) :-
    born(P, B), B =< Year,
    \+ married_in_year(P, _, Year).

widowed_in_year(P, Year) :-
    spouses(P, Q),
    died(Q, DQ), DQ =< Year,
    \+ married_in_year(P, _, Year).

marriage_duration_until_year(X, Y, Year, Dur) :-
    spouses(X, Y),
    (married(X, Y, S) ; married(Y, X, S)),
    ( (divorced(X, Y, E) ; divorced(Y, X, E))
      -> (E =< Year -> End is E ; End is Year)
      ;  End is Year ),
    Dur is End - S, Dur >= 0.

marriage_started_before_or_in(X, Y, Year) :-
    (married(X, Y, S) ; married(Y, X, S)), S =< Year.

marriage_ended_before_or_in(X, Y, Year) :-
    (divorced(X, Y, E) ; divorced(Y, X, E)), E =< Year.

bio_father(F, C) :- male(F), biological_child_of(C, F, _).
bio_mother(M, C) :- female(M), biological_child_of(C, _, M).

adoptive_parent_in_year(P, C, Year) :-
    adopted_by(C, P, _, A), A =< Year.
adoptive_parent_in_year(P, C, Year) :-
    adopted_by(C, _, P, A), A =< Year.

legal_parent_in_year(P, C, Year) :-
    biological_child_of(C, F, M),
    born(C, BC), BC =< Year,
    (P = F ; P = M).
legal_parent_in_year(P, C, Year) :-
    adoptive_parent_in_year(P, C, Year).

father_in_year(F, C, Year) :-
    legal_parent_in_year(F, C, Year), male(F).

mother_in_year(M, C, Year) :-
    legal_parent_in_year(M, C, Year), female(M).

parent_in_year(P, C, Year) :-
    father_in_year(P, C, Year) ; mother_in_year(P, C, Year).

sibling(X, Y) :-
    biological_child_of(X, F, M),
    biological_child_of(Y, F, M),
    X \= Y.

half_sibling(X, Y) :-
    biological_child_of(X, F1, M1),
    biological_child_of(Y, F2, M2),
    X \= Y,
    (F1 = F2 ; M1 = M2),
    \+ (F1 = F2, M1 = M2).

grandparent_in_year(G, C, Year) :-
    parent_in_year(G, P, Year),
    parent_in_year(P, C, Year).

ancestor_in_year(A, D, Year) :-
    parent_in_year(A, D, Year).
ancestor_in_year(A, D, Year) :-
    parent_in_year(A, X, Year),
    ancestor_in_year(X, D, Year).

descendant_in_year(D, A, Year) :-
    ancestor_in_year(A, D, Year).

step_parent_in_year(SP, C, Year) :-
    parent_in_year(P, C, Year),
    married_in_year(P, SP, Year),
    SP \= P.

cousin_in_year(X, Y, Year) :-
    parent_in_year(P1, X, Year),
    parent_in_year(P2, Y, Year),
    (sibling(P1, P2) ; half_sibling(P1, P2)),
    X \= Y.
