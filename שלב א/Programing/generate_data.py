"""
METHOD B - Python generator for INSERT statements.

Outputs:
  Programing/generatedInserts.sql  - this script's own output (method B only)
  insertTables.sql                 - full insert file: methods A + B + C

The full file combines the three data-population methods:
  A. ManualInserts/manualInserts.sql           - hand-written INSERTs
  B. this script                               - generated INSERTs
  C. PostgresGenerateSeries/generateSeries.sql - generate_series() in Postgres

Standard library only. random.seed() makes every run produce the same data.
Usage (from the "שלב א" folder):  python Programing/generate_data.py
"""

import random
from datetime import date, timedelta
from pathlib import Path

random.seed(2026)

ROOT = Path(__file__).resolve().parent.parent          # the "שלב א" folder
METHOD_A = ROOT / "ManualInserts" / "manualInserts.sql"
METHOD_C = ROOT / "PostgresGenerateSeries" / "generateSeries.sql"
OUT_B = ROOT / "Programing" / "generatedInserts.sql"
OUT_FULL = ROOT / "insertTables.sql"
BATCH = 500  # rows per multi-row INSERT statement

# ---------------------------------------------------------------------------
# Row counts and id ranges. Method C relies on these ranges.
# ---------------------------------------------------------------------------
N_MANAGERS = 500           # staff 1..500     -> DORM_MANAGER
N_CASHIERS = 600           # staff 501..1100  -> CASHIER
N_OTHER_STAFF = 100        # staff 1101..1200 (other roles, superclass only)
N_STUDENTS = 3000          # students 100001..103000
FIRST_STUDENT_ID = 100001
N_BUILDINGS = 500
N_CATEGORIES = 500         # 12 manual (method A) + 488 generated
N_MENU_ITEMS = 1000
N_GYM = 2500
MANUAL_CATEGORIES = ["Breakfast", "Main Course", "Salads", "Soups", "Sandwiches",
                     "Pasta", "Grill", "Side Dishes", "Desserts", "Hot Drinks",
                     "Cold Drinks", "Snacks"]

FIRST_NAMES = """Noa Tamar Yael Maya Shira Avigail Adi Michal Hila Neta Rivka Sarah
Leah Rachel Esther Chana Miriam Dina Ayelet Hadas Efrat Moriah Talia Yaara Liron
Daniel David Yosef Moshe Avraham Yitzchak Yaakov Eitan Itai Omer Noam Ariel Amit
Yonatan Elad Ido Uri Lior Roi Gilad Asaf Nadav Tomer Yehuda Elyassaf Shlomo Meir
Natan Binyamin Akiva Chaim Ezra Boaz Gidon Matan Oren Ran Shai Yoav Ziv Avi Dov
Eliya Hodaya Naama Racheli Shoshana Tzipora Yocheved Ora Orly Galit Keren Liat""".split()

LAST_NAMES = """Cohen Levi Mizrahi Peretz Biton Dahan Avraham Friedman Agbaria Malka
Azoulay Katz Yosef David Amar Ohana Hadad Gabay Ben-David Shapira Ben-Haim Klein
Weiss Rosenberg Goldberg Shalom Elbaz Vaknin Sabag Halevi Ashkenazi Toledano
Ben-Ami Carmi Eliyahu Golan Harel Kaplan Lavi Margalit Nachum Oz Rubin Segal
Tal Zohar Barak Dror Even Gross Hoffman Kedar Lerner Mor Navon Ofer Paz Raz Sharon
Yaron Zilber Ben-Shimon Bar-Lev Stern Zur Alon Gefen Peled Regev Sasson Tzur""".split()

CAMPUSES = ["Givat Ram", "Mount Scopus", "Ein Kerem", "Rehovot", "Lev Campus",
            "Tal Campus", "Ramat Aviv", "Beer Sheva", "Haifa Carmel", "Ariel"]
BUILDING_WORDS = """Oren Alon Erez Brosh Tamar Rimon Zayit Te'ena Gefen Shaked Dekel
Ella Hadas Narkis Rakefet Kalanit Irus Shoshan Lotem Rotem Shikma Arava Tidhar
Luz Ketura Ofer Tzur Galil Carmel Hermon Tavor Gilboa Negev Arbel Meron Nitzan
Savyon Yasmin Dafna Mor Levona Kinneret Yarden Snir Dan Banias""".split()


def esc(v):
    """Render a Python value as a SQL literal."""
    if isinstance(v, bool):
        return "TRUE" if v else "FALSE"
    if isinstance(v, (int, float)):
        return str(v)
    if isinstance(v, date):
        return f"'{v.isoformat()}'"
    return "'" + str(v).replace("'", "''") + "'"


def inserts(table, columns, rows):
    """Multi-row INSERT statements, BATCH rows each."""
    out = [f"-- {table}: {len(rows)} rows"]
    for i in range(0, len(rows), BATCH):
        chunk = rows[i:i + BATCH]
        values = ",\n".join("  (" + ", ".join(esc(v) for v in r) + ")" for r in chunk)
        out.append(f"INSERT INTO {table} ({', '.join(columns)}) VALUES\n{values};")
    return "\n".join(out) + "\n"


def rand_date(start, end):
    return start + timedelta(days=random.randint(0, (end - start).days))


def unique_phones(n):
    """n distinct Israeli mobile numbers: 05X + 7 digits."""
    nums = random.sample(range(10_000_000), n)
    return [f"05{random.choice('0234578')}{x:07d}" for x in nums]


def add_months(d, months):
    y, m = divmod(d.month - 1 + months, 12)
    return date(d.year + y, m + 1, min(d.day, 28))


# ---------------------------------------------------------------------------
# STAFF_MEMBER, DORM_MANAGER, CASHIER
# ---------------------------------------------------------------------------
n_staff = N_MANAGERS + N_CASHIERS + N_OTHER_STAFF
staff_phones = unique_phones(n_staff)
staff = [(i, random.choice(FIRST_NAMES), random.choice(LAST_NAMES), staff_phones[i - 1],
          rand_date(date(1995, 1, 1), date(2026, 9, 30)))
         for i in range(1, n_staff + 1)]

emergency = unique_phones(N_MANAGERS)
managers = [(i, emergency[i - 1]) for i in range(1, N_MANAGERS + 1)]

cashiers = [(i, random.randint(1, 50), random.choice(["morning", "evening", "night"]))
            for i in range(N_MANAGERS + 1, N_MANAGERS + N_CASHIERS + 1)]

# ---------------------------------------------------------------------------
# STUDENT
# ---------------------------------------------------------------------------
student_phones = unique_phones(N_STUDENTS)
students = []
for k in range(N_STUDENTS):
    sid = FIRST_STUDENT_ID + k
    fn, ln = random.choice(FIRST_NAMES), random.choice(LAST_NAMES)
    email = f"{fn}.{ln}{sid % 100000}@post.campus.ac.il".lower()
    students.append((sid, fn, ln, student_phones[k], email,
                     rand_date(date(1985, 1, 1), date(2007, 12, 31))))
student_ids = [s[0] for s in students]

# ---------------------------------------------------------------------------
# Legacy random draws.
# An earlier version of the schema had a ROOM_TYPE table. It was removed
# (room capacity is now stored in ROOM), but these random calls are kept so
# the generated data stays identical to the data in the existing backups.
# Their results are not used.
# ---------------------------------------------------------------------------
_legacy_pool = [f"{c} {f} {g}"
                for c in ["Single", "Double", "Triple", "Quad", "Studio", "Twin", "Loft", "Duplex"]
                for f in ["Balcony", "Kitchenette", "Garden View", "Renovated", "Quiet Floor",
                          "Shared Bath", "Private Bath", "Corner", "Air Conditioned", "City View",
                          "Ground Floor", "Top Floor", "Furnished", "Large", "Compact", "Sea View"]
                for g in ["Basic", "Standard", "Plus", "Premium"]
                if len(f"{c} {f} {g}") <= 30]
random.shuffle(_legacy_pool)


def legacy_draw():
    random.choice(range(1, 501))


# ---------------------------------------------------------------------------
# BUILDING
# ---------------------------------------------------------------------------
buildings, used_names = [], set()
for b in range(1, N_BUILDINGS + 1):
    campus = random.choice(CAMPUSES)
    while True:
        name = f"{random.choice(BUILDING_WORDS)} {random.randint(1, 30)}"
        if (campus, name) not in used_names:            # UNIQUE (campus, building_name)
            used_names.add((campus, name))
            break
    # with 500 managers and 500 buildings, every manager gets one building
    manager = b if b <= N_MANAGERS else random.randint(1, N_MANAGERS)
    buildings.append((b, name, campus, random.randint(2, 12), manager))

# ---------------------------------------------------------------------------
# ROOM (weak entity) - every building has at least one room (has_room 1..N)
# ---------------------------------------------------------------------------
rooms = []
for b, _, _, floors, _ in buildings:
    per_floor = {}
    for _ in range(random.randint(3, 9)):
        floor = random.randint(0, floors - 1)          # floor < num_floors
        per_floor[floor] = per_floor.get(floor, 0) + 1
        room_number = floor * 100 + per_floor[floor]
        rooms.append((b, room_number, floor, random.randint(1, 4)))   # capacity 1..4
        legacy_draw()

# ---------------------------------------------------------------------------
# ASSIGNED_TO - one assignment per student per academic year (Oct 1 - Jul 31).
# Beds are drawn from the list of room places, so no room is ever over capacity
# and no student ever has two overlapping assignments.
# ---------------------------------------------------------------------------
assignments = []
beds = [(b, rn) for b, rn, _, cap in rooms for _ in range(cap)]
for year in range(2021, 2026):
    start, end = date(year, 10, 1), date(year + 1, 7, 31)
    residents = random.sample(student_ids, int(N_STUDENTS * 0.45))
    for sid, (b, rn) in zip(residents, random.sample(beds, len(residents))):
        rent = random.randint(90, 320) * 10 + (year - 2021) * 50   # rent rises yearly
        assignments.append((sid, b, rn, start, end, f"{rent:.2f}"))

# ---------------------------------------------------------------------------
# GYM_MEMBERSHIP - consecutive memberships per student, never overlapping
# ---------------------------------------------------------------------------
gym, mid = [], 0
members = random.sample(student_ids, 1400)
while len(gym) < N_GYM:
    for sid in members:
        if len(gym) >= N_GYM:
            break
        start = rand_date(date(2021, 1, 1), date(2022, 6, 30))
        for _ in range(random.randint(1, 3)):
            if len(gym) >= N_GYM:
                break
            end = add_months(start, random.choice([1, 3, 6, 12]))
            mid += 1
            gym.append((mid, start, end, sid))
            start = end + timedelta(days=random.randint(0, 120))
    # students who still have no membership get one in the next round
    members = [m for m in student_ids if m not in {g[3] for g in gym}]

# ---------------------------------------------------------------------------
# MENU_CATEGORY (generated part) and MENU_ITEM
# ---------------------------------------------------------------------------
cuisines = ["Israeli", "Italian", "Asian", "Mexican", "French", "Indian", "Greek",
            "Moroccan", "Yemenite", "American", "Japanese", "Thai", "Turkish",
            "Lebanese", "Spanish", "Georgian", "Ethiopian", "Persian", "Iraqi",
            "Vegan", "Kids", "Healthy", "Shabbat", "Holiday", "Chef Special"]
kinds = ["Breakfast", "Mains", "Salads", "Soups", "Sandwiches", "Pasta", "Grill",
         "Sides", "Desserts", "Hot Drinks", "Cold Drinks", "Snacks", "Pastries",
         "Bowls", "Wraps", "Pizza", "Rice Dishes", "Stews", "Smoothies", "Combos"]
category_pool = [f"{c} {k}" for c in cuisines for k in kinds]
random.shuffle(category_pool)
categories = [(12 + i, name) for i, name in
              enumerate(category_pool[:N_CATEGORIES - len(MANUAL_CATEGORIES)], start=1)]
category_name = dict([(i + 1, n) for i, n in enumerate(MANUAL_CATEGORIES)] + categories)

mains = {"Chicken": False, "Beef": False, "Turkey": False, "Salmon": False,
         "Tuna": False, "Lamb": False, "Schnitzel": False, "Meatballs": False,
         "Tofu": True, "Halloumi": True, "Mushroom": True, "Eggplant": True,
         "Chickpea": True, "Lentil": True, "Cheese": True, "Vegetable": True,
         "Egg": True, "Sweet Potato": True, "Falafel": True, "Shakshuka": True}
sizes = ["Small", "Regular", "Large", "Family"]
menu_items, used_items = [], set()
while len(menu_items) < N_MENU_ITEMS:
    cat = random.randint(1, N_CATEGORIES)
    main = random.choice(list(mains))
    name = f"{category_name[cat]} - {main} ({random.choice(sizes)})"
    if name in used_items or len(name) > 50:     # UNIQUE, VARCHAR(50)
        continue
    used_items.add(name)
    price = round(random.uniform(6, 85), 1)
    menu_items.append((len(menu_items) + 1, name, f"{price:.2f}", mains[main], cat))

# ---------------------------------------------------------------------------
# Write the outputs
# ---------------------------------------------------------------------------
method_b = (
    "-- =====================================================================\n"
    "-- METHOD B - INSERT statements generated by Programing/generate_data.py\n"
    "-- =====================================================================\n\n"
) + "\n".join([
    inserts("STAFF_MEMBER", ["staff_id", "first_name", "last_name", "phone", "hire_date"], staff),
    inserts("DORM_MANAGER", ["staff_id", "emergency_phone"], managers),
    inserts("CASHIER", ["staff_id", "register_number", "shift"], cashiers),
    inserts("STUDENT", ["student_id", "first_name", "last_name", "phone", "email", "birth_date"], students),
    inserts("BUILDING", ["building_id", "building_name", "campus", "num_floors", "manager_id"], buildings),
    inserts("ROOM", ["building_id", "room_number", "floor", "capacity"], rooms),
    inserts("ASSIGNED_TO", ["student_id", "building_id", "room_number", "start_date", "end_date",
                            "monthly_rent"], assignments),
    inserts("GYM_MEMBERSHIP", ["membership_id", "start_date", "end_date", "student_id"], gym),
    inserts("MENU_CATEGORY", ["category_id", "category_name"], categories),
    inserts("MENU_ITEM", ["item_id", "item_name", "price", "is_vegetarian", "category_id"], menu_items),
])
OUT_B.write_text(method_b, encoding="utf-8", newline="\n")

full = "\n".join([
    "-- =====================================================================\n"
    "--  Student Welfare DB  -  insertTables.sql\n"
    "--  GENERATED by Programing/generate_data.py - do not edit by hand.\n"
    "--  Three population methods, run in this order:\n"
    "--    A. hand-written INSERTs          (ManualInserts/manualInserts.sql)\n"
    "--    B. Python-generated INSERTs      (Programing/generatedInserts.sql)\n"
    "--    C. generate_series() in Postgres (PostgresGenerateSeries/generateSeries.sql)\n"
    "--  Run after createTables.sql. Everything runs in one transaction.\n"
    "-- =====================================================================\n",
    "BEGIN;\n",
    METHOD_A.read_text(encoding="utf-8"),
    method_b,
    METHOD_C.read_text(encoding="utf-8"),
    "COMMIT;\n",
])
OUT_FULL.write_text(full, encoding="utf-8", newline="\n")

counts = {"STAFF_MEMBER": len(staff), "DORM_MANAGER": len(managers), "CASHIER": len(cashiers),
          "STUDENT": len(students), "BUILDING": len(buildings), "ROOM": len(rooms),
          "ASSIGNED_TO": len(assignments), "GYM_MEMBERSHIP": len(gym),
          "MENU_CATEGORY": len(categories) + len(MANUAL_CATEGORIES), "MENU_ITEM": len(menu_items)}
for t, c in counts.items():
    print(f"{t:<16}{c:>7}")
for p in (OUT_B, OUT_FULL):
    print(f"wrote {p.relative_to(ROOT)} ({p.stat().st_size / 1e6:.1f} MB)")
