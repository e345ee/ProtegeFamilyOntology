import re
import importlib

fq = importlib.import_module("family_queries")

def has_any(items, text):
    return any(i in text for i in items)

def norm(s: str) -> str:
    return s.strip().lower()


def test_module_loaded():
    assert hasattr(fq, "answer"), "В модуле нет функции answer()"
    out = fq.answer("Кто жив в 2024 году?")
    assert "живые в 2024" in out.lower()


def test_parents_grigoriy():
    out = fq.answer("Кто родители sadovoy_grigoriy?")
    low = out.lower()
    assert "родители sadovoy_grigoriy" in low
    assert "sadovaya_marina" in low
    assert "lyutikov_vladimir" in low

def test_children_dmitriy():
    out = fq.answer("Кто дети sadovoy_dmitriy?")
    low = out.lower()
    assert "дети sadovoy_dmitriy" in low
    for child in ["sadovaya_anna", "sadovaya_olga", "sadovaya_natalya"]:
        assert child in low

def test_spouse_marina():
    out = fq.answer("Кто супруг(а) sadovaya_marina?")
    assert "lyutikov_vladimir" in out


def test_divorces_2016():
    out = fq.answer("Кто разводился в 2016 году?")
    low = out.lower()
    assert "sadovaya_marina" in low
    assert "lyutikov_vladimir" in low

def test_marriages_after_2000():
    out = fq.answer("Какие браки были после 2000 года?")
    low = out.lower()
    assert has_any(
        ["sadovoy_andrey", "shkafchik_agnes", "sadovoy_dmitriy",
         "ubuntu_svetlana", "sadovaya_marina", "lyutikov_vladimir",
         "vazovskiy_mike", "sadovoy_ivan"], low
    )


def test_born_2004():
    out = fq.answer("Какие люди родились в 2004 году?")
    low = out.lower()
    for p in ["sadovoy_grigoriy", "faktorovich_aleksandra", "sadovoy_ivan"]:
        assert p in low

def test_birth_year_dmitriy():
    out = fq.answer("Какой год рождения у sadovoy_dmitriy?")
    assert re.search(r"\b1979\b", out)

def test_death_year_arkadiy():
    out = fq.answer("Какой год смерти у sadovoy_arkadiy?")
    assert re.search(r"\b1999\b", out)

def test_alive_2024_contains_and_excludes():
    out = fq.answer("Кто жив в 2024 году?")
    low = out.lower()
    assert "sadovoy_grigoriy" in low
    assert "sadovoy_arkadiy" not in low


def test_common_ancestors_ivan_grigoriy():
    out = fq.answer("Есть ли общие предки у sadovoy_ivan и sadovoy_grigoriy?")
    assert norm(out) in ["да", "нет"], "Ответ должен быть 'Да' или 'Нет'"
    assert norm(out) == "да"

def test_grandfather_aleksandr_st_of_dmitriy():
    out = fq.answer("Может ли sadovoy_aleksandr_st быть дедушкой sadovoy_dmitriy?")
    assert norm(out) in ["да", "нет"]
    assert norm(out) == "да"

def test_name_suggestion():
    out = fq.answer("Какой год рождения у sadovoi_dmitriy?")
    assert "не найдено" in out.lower() or "возможно, вы имели в виду" in out.lower()
