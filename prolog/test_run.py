from pyswip import Prolog
import sys, atexit


class Tee:
    def __init__(self, *streams):
        self.streams = streams
    def write(self, data):
        for s in self.streams:
            if not s.closed:
                s.write(data)
                s.flush()
    def flush(self):
        for s in self.streams:
            if not s.closed:
                s.flush()


logfile = open("output.txt", "w", encoding="utf-8")
tee = Tee(sys.__stdout__, logfile)
sys.stdout = tee


@atexit.register
def close_log():
    if not logfile.closed:
        logfile.flush()
        logfile.close()


prolog = Prolog()
prolog.consult("family_tree.pl")


for r in prolog.query("born(X,_)"):
    print("Загружен:", r["X"])

def q(label, query, vars=("X","Y")):
    print("\n" + label + "\n" + "-"*40)
    results = list(prolog.query(query))
    if not results:
        print("(нет решений)")
    else:
        for r in results:
            if len(vars) == 0:
                print("Да")
            elif len(vars) == 1:
                print(r[vars[0]])
            elif len(vars) == 2:
                print(f"{r[vars[0]]} — {r[vars[1]]}")
            else:
                print({k: r[k] for k in vars if k in r})

q("Браки в 1978", "married_in_year(X,Y,1978)")
q("Супруг(а) Дмитрия в 2005", "married_in_year(sadovoy_dmitriy,Y,2005)", ("Y",))
q("Разводы в 2009", "divorced_in_year(X,Y,2009)")
q("Отец Георгия в 2007", "father_in_year(X,faktorovich_georgiy,2007)", ("X",))
q("Мать Григория в 2016", "mother_in_year(X,sadovoy_grigoriy,2016)", ("X",))
q("Маргарита холоста в 2010?", "single_in_year(sadovaya_margarita,2010)", ())
q("Вдовцы/вдовы в 2024", "widowed_in_year(X,2024)", ("X",))
q("Отчим/мачеха Григория в 2015", "step_parent_in_year(X,sadovoy_grigoriy,2015)", ("X",))
q("Кузены: Григорий ~ Александра (2015)?",
  "cousin_in_year(sadovoy_grigoriy,faktorovich_aleksandra,2015)", ())
q("Возраст Александра мл. в 2020", "age_in_year(sadovoy_aleksandr_ml,2020,A)", ("A",))
q("Аркадий жив в 1985?", "alive_in_year(sadovoy_arkadiy,1985)", ())
q("Марина и Владимир в браке в 2016?",
  "married_in_year(sadovaya_marina,lyutikov_vladimir,2016)", ())

print("\nГотово.")
