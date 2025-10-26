:- use_module(library(semweb/rdf11)).
:- use_module(library(semweb/rdf_turtle_write)).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(yall)).

% ===== NS =====
:- rdf_register_prefix(fam, 'http://example.org/family#').
:- rdf_register_prefix(xsd, 'http://www.w3.org/2001/XMLSchema#').
:- rdf_register_prefix(rdf, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#').
:- rdf_register_prefix(rdfs,'http://www.w3.org/2000/01/rdf-schema#').
:- rdf_register_prefix(owl, 'http://www.w3.org/2002/07/owl#').

% ===== helper: сделать IRI из локального имени =====
qname(Local0, IRI) :-
    ( atom(Local0) -> Local = Local0 ; atom_string(Local, Local0) ),
    Term =.. [':', fam, Local],
    rdf_global_id(Term, IRI).

% ===== Классы/свойства =====
class('Person'). class('Marriage'). class('Divorce'). class('Adoption').
class('Male').   class('Female').

op('hasParent'). op('hasFather'). op('hasMother'). op('hasChild').
op('spouseOf').  op('marriedPerson'). op('divorcedPerson').
op('adoptedPerson'). op('adoptiveParent').
op('bioFather'). op('bioMother').

dp('birthYear'). dp('deathYear'). dp('eventYear').

% ===== Схема =====
ensure_schema :-
  forall(class(C), ( qname(C, CI), rdf_assert(CI, rdf:type, owl:'Class') )),
  forall(op(P),    ( qname(P, PI), rdf_assert(PI, rdf:type, owl:'ObjectProperty') )),
  forall(dp(D),    ( qname(D, DI), rdf_assert(DI, rdf:type, owl:'DatatypeProperty') )),

  qname('hasFather', HF), qname('hasParent', HP),
  qname('hasMother', HM), qname('hasChild', HC),
  qname('spouseOf', SO),
  qname('bioFather', BF), qname('bioMother', BM),

  rdf_assert(HF, rdfs:subPropertyOf, HP),
  rdf_assert(HM, rdfs:subPropertyOf, HP),
  rdf_assert(HC, owl:inverseOf,      HP),

  rdf_assert(SO, rdf:type, owl:'SymmetricProperty'),
  rdf_assert(SO, rdf:type, owl:'IrreflexiveProperty'),

  rdf_assert(BF, rdfs:subPropertyOf, HF),
  rdf_assert(BM, rdfs:subPropertyOf, HM).

% ===== Утилиты =====
iri_local_from_atom(Atom, Local) :-
  atom_string(Atom, S0),
  normalize_space(string(S1), S0),
  string_lower(S1, S2),
  re_replace('[^a-z0-9_]'/g, '_', S2, S3),
  atom_string(Local, S3).

iri_person(NameAtom, IRI) :-
  iri_local_from_atom(NameAtom, Local),
  qname(Local, IRI).

assert_year_int(PredName, S, Year) :-
  qname(PredName, Pred),
  (number(Year) -> Y is Year ; atom_number(Year, Y)),
  rdf_assert(S, Pred, (Y^^xsd:integer)).

assert_person_if_needed(P) :-
  iri_person(P, IRI),
  ( rdf(IRI, rdf:type, _) ->
      true
  ; qname('Person', PersonC),
    rdf_assert(IRI, rdf:type, PersonC)
  ).

% ===== Главный экспорт =====
export_family_ontology(File) :-
  rdf_reset_db,
  ensure_schema,

  % 1) персоны и пол
  forall(person(P, Gender),
    ( assert_person_if_needed(P),
      iri_person(P, IRI),
      ( Gender == male   -> qname('Male',   MC), rdf_assert(IRI, rdf:type, MC)
      ; Gender == female -> qname('Female', FC), rdf_assert(IRI, rdf:type, FC)
      ; true )
    )),

  % 2) birth/death
  forall(born(P, BY),
    ( assert_person_if_needed(P),
      iri_person(P, IRI),
      assert_year_int('birthYear', IRI, BY)
    )),
  forall(died(P, DY),
    ( assert_person_if_needed(P),
      iri_person(P, IRI),
      assert_year_int('deathYear', IRI, DY)
    )),

  % 3) биологические родители
  qname('hasParent',      HP),
  qname('hasFather',      HF),
  qname('hasMother',      HM),
  qname('bioFather',      BF),
  qname('bioMother',      BM),
  forall(biological_child_of(C, F, M),
    ( assert_person_if_needed(C), assert_person_if_needed(F), assert_person_if_needed(M),
      iri_person(C, CI), iri_person(F, FI), iri_person(M, MI),
      rdf_assert(CI, HP, FI),
      rdf_assert(CI, HP, MI),
      rdf_assert(CI, HF, FI),
      rdf_assert(CI, HM, MI),
      rdf_assert(CI, BF, FI),
      rdf_assert(CI, BM, MI)
    )),

  % 4) усыновления
  qname('Adoption', AC),
  qname('adoptedPerson',   ADP),
  qname('adoptiveParent',  ADPR),
  forall(adopted_by(Child, P1, P2, Year),
    ( assert_person_if_needed(Child),
      assert_person_if_needed(P1),
      assert_person_if_needed(P2),
      iri_person(Child, CI), iri_person(P1, P1I), iri_person(P2, P2I),
      format(atom(Local), 'adopt_~w_~w_~w_~w', [Child,P1,P2,Year]),
      qname(Local, A),
      rdf_assert(A, rdf:type, AC),
      rdf_assert(A, ADP, CI),
      rdf_assert(A, ADPR, P1I),
      rdf_assert(A, ADPR, P2I),
      assert_year_int('eventYear', A, Year),
      rdf_assert(CI, HP, P1I),
      rdf_assert(CI, HP, P2I),
      rdf_assert(CI, ADPR, P1I),
      rdf_assert(CI, ADPR, P2I)
    )),

  % 5) браки/разводы (события)
  qname('Marriage', MC),
  qname('Divorce',  DC),
  qname('marriedPerson',  MP),
  qname('divorcedPerson', DP),
  qname('spouseOf', SO),
  forall(married(X, Y, Year),
    ( assert_person_if_needed(X), assert_person_if_needed(Y),
      iri_person(X, XI), iri_person(Y, YI),
      format(atom(L), 'mar_~w_~w_~w', [X,Y,Year]),
      qname(L, M),
      rdf_assert(M, rdf:type, MC),
      rdf_assert(M, MP, XI),
      rdf_assert(M, MP, YI),
      assert_year_int('eventYear', M, Year),
      rdf_assert(XI, SO, YI)
    )),
  forall(divorced(X, Y, Year),
    ( assert_person_if_needed(X), assert_person_if_needed(Y),
      iri_person(X, XI), iri_person(Y, YI),
      format(atom(L2), 'div_~w_~w_~w', [X,Y,Year]),
      qname(L2, D),
      rdf_assert(D, rdf:type, DC),
      rdf_assert(D, DP, XI),
      rdf_assert(D, DP, YI),
      assert_year_int('eventYear', D, Year)
    )),

  % 6) сохранить
  rdf_save_turtle(File, [indent(2)]).


export_ttl :-
  export_family_ontology('../protege/family.ttl'),
  format('Сохранено в family.ttl~n').
