from rdflib import Graph, Namespace, Literal, XSD
import re, difflib

g = Graph()
g.parse("family.ttl", format="turtle")

FAM = Namespace("http://example.org/family#")


def q(query):
    results = g.query(query, initNs={"fam": FAM, "xsd": XSD})
    out = []
    for row in results:
        val = str(list(row)[0])
        if "#" in val:
            out.append(val.split("#")[-1])
        else:
            out.append(val)
    return list(set(out))

def scalar(query):
    results = list(g.query(query, initNs={"fam": FAM, "xsd": XSD}))
    if results:
        val = str(results[0][0])
        return val.split('"')[1] if '"' in val else val
    return None

def known_people():
    qstr = "SELECT DISTINCT ?p WHERE { ?p a fam:Person . }"
    people = q(qstr)
    return [p.lower() for p in people]

def check_name(name):
    names = known_people()
    if name not in names:
        suggestion = difflib.get_close_matches(name, names, n=1)
        if suggestion:
            return f"Имя '{name}' не найдено. Возможно, вы имели в виду '{suggestion[0]}'?"
        else:
            return f"Имя '{name}' не найдено в базе."
    return None


def parents(person): return q(f"SELECT ?p WHERE {{ fam:{person} fam:hasParent ?p . }}")
def children(person): return q(f"SELECT ?c WHERE {{ ?c fam:hasParent fam:{person} . }}")
def spouses(person):  return q(f"SELECT ?s WHERE {{ fam:{person} fam:spouseOf ?s . }}")
def birth_year(person): return scalar(f"SELECT ?y WHERE {{ fam:{person} fam:birthYear ?y . }}")
def death_year(person): return scalar(f"SELECT ?y WHERE {{ fam:{person} fam:deathYear ?y . }}")

def born_in_year(year):
    return q(f'SELECT ?p WHERE {{ ?p fam:birthYear "{year}"^^xsd:integer . }}')

def alive_in_year(year):
    return q(f"""
    SELECT DISTINCT ?p WHERE {{
        ?p fam:birthYear ?b .
        OPTIONAL {{ ?p fam:deathYear ?d . }}
        FILTER(xsd:integer(?b) <= {year} && (!bound(?d) || xsd:integer(?d) >= {year}))
    }}
    """)

def marriages_after_year(year):
    query = f"""
    SELECT DISTINCT ?p WHERE {{
        ?m a fam:Marriage ;
           fam:marriedPerson ?p ;
           fam:eventYear ?y .
        FILTER(xsd:integer(?y) > {year})
    }}
    """
    return q(query)

def common_ancestors(p1, p2):
    query_common = """
    PREFIX fam: <http://example.org/family#>
    SELECT DISTINCT ?anc WHERE {
        fam:sadovoy_ivan fam:hasParent+ ?anc .
        fam:sadovoy_grigoriy fam:hasParent+ ?anc .
    }
    """
    res = g.query(query_common, initNs={"fam": FAM})
    for row in res:
        return bool(row)

def list_common_ancestors(p1, p2):
    query = f"""
    SELECT DISTINCT ?anc WHERE {{
        fam:{p1} fam:hasParent+ ?anc .
        fam:{p2} fam:hasParent+ ?anc .
    }}
    """
    res = g.query(query, initNs={"fam": FAM})
    names = []
    for row in res:
        val = str(row[0])
        names.append(val.split("#")[-1])
    return names

def is_grandfather_of(p1, p2):
    query = f"""
    ASK {{
        fam:{p1} a fam:Male .
        fam:{p2} fam:hasParent ?parent .
        ?parent fam:hasParent fam:{p1} .
    }}
    """
    res = g.query(query, initNs={"fam": FAM})
    for row in res:
        return bool(row)

def divorces_in_year(year):
    query = f"""
    SELECT DISTINCT ?p WHERE {{
        ?div a fam:Divorce ;
             fam:divorcedPerson ?p ;
             fam:eventYear "{year}"^^xsd:integer .
    }}
    """
    return q(query)

def answer(question):
    question = question.lower().strip()

    if "родители" in question:
        name = re.findall(r"([a-z_]+)", question)[-1]
        chk = check_name(name)
        if chk: return chk
        return f"Родители {name}: {parents(name) or 'не найдены'}"

    if "дети" in question:
        name = re.findall(r"([a-z_]+)", question)[-1]
        chk = check_name(name)
        if chk: return chk
        return f"Дети {name}: {children(name) or 'не найдены'}"

    if "браки" in question and "после" in question:
        year = re.findall(r"(\d{4})", question)[0]
        res = marriages_after_year(year)
        return f"Браки после {year}: {res or 'нет данных'}"

    if "общие предки" in question:
        names = re.findall(r"([a-z_]+)", question)
        if len(names) >= 2:
            p1, p2 = names[-2], names[-1]
            chk1, chk2 = check_name(p1), check_name(p2)
            if chk1: return chk1
            if chk2: return chk2
            return "Да" if common_ancestors(p1, p2) else "Нет"
        else:
            return "Укажите два имени, например: Есть ли общие предки у sadovoy_ivan и sadovoy_grigoriy?"

    if "дедуш" in question:
        names = re.findall(r"([a-z_]+)", question)
        if len(names) >= 2:
            p1, p2 = names[-2], names[-1]
            chk1, chk2 = check_name(p1), check_name(p2)
            if chk1: return chk1
            if chk2: return chk2
            return "Да" if is_grandfather_of(p1, p2) else "Нет"
        else:
            return "Укажите два имени, например: Может ли sadovoy_dmitriy быть дедушкой faktorovich_georgiy?"


    if "супруг" in question:
        name = re.findall(r"([a-z_]+)", question)[-1]
        chk = check_name(name)
        if chk: return chk
        return f"Супруг(а) {name}: {spouses(name) or 'не найден(а)'}"

    if "кто развод" in question or "разводил" in question:
        match = re.findall(r"(\d{4})", question)
        if match:
            year = match[0]
            res = divorces_in_year(year)
            return f"Разводившиеся в {year}: {res or 'нет данных'}"
        else:
            return "Уточните год: например, 'Кто разводился в 2016 году?'"

    if "какой год рождения" in question:
        name = re.findall(r"([a-z_]+)", question)[-1]
        chk = check_name(name)
        if chk: return chk
        res = birth_year(name)
        return f"Год рождения {name}: {res or 'не указан'}"

    if "какой год смерти" in question:
        name = re.findall(r"([a-z_]+)", question)[-1]
        chk = check_name(name)
        if chk: return chk
        res = death_year(name)
        return f"Год смерти {name}: {res or 'не указан'}"

    if "кто родился" in question or "какие люди родились" in question:
        year = re.findall(r"(\d{4})", question)[0]
        res = born_in_year(year)
        return f"Родившиеся в {year}: {res or 'нет данных'}"

    if "жив" in question or "живы" in question:
        year = re.findall(r"(\d{4})", question)[0]
        res = alive_in_year(year)
        return f"Живые в {year}: {res or 'нет данных'}"

    return "Извини, я не понимаю этот вопрос."


HELP_TEXT = """
Примеры возможных вопросов:
Кто родители sadovoy_grigoriy?
Кто дети sadovoy_dmitriy?
Кто супруг(а) sadovaya_marina?
Какой год рождения у sadovoy_dmitriy?
Какой год смерти у sadovoy_arkadiy?
Какие люди родились в 2004 году?
Кто жив в 2024 году?
Может ли sadovoy_dmitriy быть дедушкой faktorovich_georgiy?
Есть ли общие предки у sadovoy_ivan и sadovoy_grigoriy?
Кто разводился в 2016 году?
Какие браки были после 2000 года?
"""



def main():
    print(HELP_TEXT)
    print("Для выхода — 'выход' или 'exit'\n")

    while True:
        q_user = input("> ")
        if q_user.lower() in ["выход", "exit", "quit"]:
            break
        print(answer(q_user))

if __name__ == "__main__":
    main()
