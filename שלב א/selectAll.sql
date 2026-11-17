-- =====================================================================
--  Student Welfare DB  -  selectAll.sql
--  Returns all rows of every table, in creation order.
-- =====================================================================

SELECT * FROM STAFF_MEMBER;
SELECT * FROM DORM_MANAGER;
SELECT * FROM CASHIER;
SELECT * FROM STUDENT;
SELECT * FROM BUILDING;
SELECT * FROM ROOM;
SELECT * FROM ASSIGNED_TO;
SELECT * FROM GYM_MEMBERSHIP;
SELECT * FROM TUTORING_SESSION;
SELECT * FROM MENU_CATEGORY;
SELECT * FROM MENU_ITEM;
SELECT * FROM MEAL_PURCHASE;
SELECT * FROM INCLUDES;

-- Row count of every table (quick check that all data was inserted)
SELECT 'STAFF_MEMBER' AS table_name, COUNT(*) AS row_count FROM STAFF_MEMBER
UNION ALL
SELECT 'DORM_MANAGER' AS table_name, COUNT(*) AS row_count FROM DORM_MANAGER
UNION ALL
SELECT 'CASHIER' AS table_name, COUNT(*) AS row_count FROM CASHIER
UNION ALL
SELECT 'STUDENT' AS table_name, COUNT(*) AS row_count FROM STUDENT
UNION ALL
SELECT 'BUILDING' AS table_name, COUNT(*) AS row_count FROM BUILDING
UNION ALL
SELECT 'ROOM' AS table_name, COUNT(*) AS row_count FROM ROOM
UNION ALL
SELECT 'ASSIGNED_TO' AS table_name, COUNT(*) AS row_count FROM ASSIGNED_TO
UNION ALL
SELECT 'GYM_MEMBERSHIP' AS table_name, COUNT(*) AS row_count FROM GYM_MEMBERSHIP
UNION ALL
SELECT 'TUTORING_SESSION' AS table_name, COUNT(*) AS row_count FROM TUTORING_SESSION
UNION ALL
SELECT 'MENU_CATEGORY' AS table_name, COUNT(*) AS row_count FROM MENU_CATEGORY
UNION ALL
SELECT 'MENU_ITEM' AS table_name, COUNT(*) AS row_count FROM MENU_ITEM
UNION ALL
SELECT 'MEAL_PURCHASE' AS table_name, COUNT(*) AS row_count FROM MEAL_PURCHASE
UNION ALL
SELECT 'INCLUDES' AS table_name, COUNT(*) AS row_count FROM INCLUDES;
