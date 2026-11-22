-- =====================================================================
-- METHOD C - data generated inside PostgreSQL with generate_series()
-- Used for the large transaction tables:
--   TUTORING_SESSION   5,000 rows
--   MEAL_PURCHASE     30,000 rows
--   INCLUDES         ~75,000 rows (1-4 different items per purchase)
-- Depends on the ids that method B creates:
--   students 100001..103000, cashiers 501..1100, menu items 1..1000
-- setseed() makes random() repeatable, so every run produces the same data.
-- =====================================================================

SELECT setseed(0.2026);

-- ---------- TUTORING_SESSION ----------
INSERT INTO TUTORING_SESSION (session_id, course_name, session_date, hours, tutor_id, tutee_id)
WITH r AS (
  SELECT g                                AS session_id,
         floor(random() * 30)::int + 1    AS course_idx,
         floor(random() * 1857)::int      AS day_offset,   -- 2021-10-01 .. 2026-10-31
         floor(random() * 8)::int + 1     AS half_hours,   -- 0.5 .. 4.0 hours
         floor(random() * 3000)::int      AS tutor_off,
         floor(random() * 2999)::int + 1  AS tutee_shift   -- 1..2999, so tutee <> tutor
  FROM generate_series(1, 5000) AS g
)
SELECT session_id,
       (ARRAY['Calculus 1','Calculus 2','Linear Algebra','Discrete Mathematics',
              'Probability','Statistics','Physics 1','Physics 2','Intro to CS',
              'Data Structures','Algorithms','Databases','Operating Systems',
              'Computer Networks','Object Oriented Programming','Logic Design',
              'Computer Architecture','Software Engineering','Machine Learning',
              'Organic Chemistry','General Chemistry','Biology','Microeconomics',
              'Macroeconomics','Accounting','Academic English','Talmud',
              'Jewish Philosophy','Electronics','Signals and Systems'])[course_idx],
       DATE '2021-10-01' + day_offset,
       half_hours * 0.5,
       100001 + tutor_off,
       100001 + (tutor_off + tutee_shift) % 3000
FROM r;

-- ---------- MEAL_PURCHASE ----------
INSERT INTO MEAL_PURCHASE (purchase_id, purchase_date, payment_method, student_id, cashier_id)
WITH r AS (
  SELECT g                               AS purchase_id,
         floor(random() * 1765)::int     AS day_offset,    -- 2022-01-01 .. 2026-10-31
         floor(random() * 4)::int + 1    AS pay_idx,
         floor(random() * 3000)::int     AS student_off,
         floor(random() * 600)::int      AS cashier_off
  FROM generate_series(1, 30000) AS g
)
SELECT purchase_id,
       DATE '2022-01-01' + day_offset,
       (ARRAY['cash','credit_card','student_card','mobile'])[pay_idx],
       100001 + student_off,
       501 + cashier_off
FROM r;

-- ---------- INCLUDES ----------
-- Each purchase gets 1-4 items. Because k*729 mod 1000 gives a different
-- value for each k = 1..4, the items within a purchase are always distinct.
INSERT INTO INCLUDES (purchase_id, item_id, quantity)
SELECT p.purchase_id,
       ((p.purchase_id * 7919 + k * 729) % 1000) + 1,
       floor(random() * 3)::int + 1
FROM MEAL_PURCHASE AS p
CROSS JOIN LATERAL generate_series(1, 1 + p.purchase_id % 4) AS k;
