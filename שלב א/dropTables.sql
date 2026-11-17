-- =====================================================================
--  Student Welfare DB  -  dropTables.sql
--  Drops all tables in reverse foreign-key order:
--  tables that reference others are dropped before the tables they reference,
--  so the script runs without errors and without CASCADE.
-- =====================================================================

DROP TABLE IF EXISTS INCLUDES;
DROP TABLE IF EXISTS MEAL_PURCHASE;
DROP TABLE IF EXISTS MENU_ITEM;
DROP TABLE IF EXISTS MENU_CATEGORY;
DROP TABLE IF EXISTS TUTORING_SESSION;
DROP TABLE IF EXISTS GYM_MEMBERSHIP;
DROP TABLE IF EXISTS ASSIGNED_TO;
DROP TABLE IF EXISTS ROOM;
DROP TABLE IF EXISTS BUILDING;
DROP TABLE IF EXISTS STUDENT;
DROP TABLE IF EXISTS CASHIER;
DROP TABLE IF EXISTS DORM_MANAGER;
DROP TABLE IF EXISTS STAFF_MEMBER;
