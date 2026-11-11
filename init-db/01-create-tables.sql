-- =====================================================================
--  Student Welfare DB  -  createTables.sql
--  Generated from welfare_ERD.erdplus (ERD -> relational schema, 3NF)
--  Target: PostgreSQL
--
--  Creation order respects foreign-key dependencies:
--    STAFF_MEMBER -> DORM_MANAGER, CASHIER
--    STUDENT
--    BUILDING -> ROOM_TYPE -> ROOM -> ASSIGNED_TO
--    GYM_MEMBERSHIP, TUTORING_SESSION
--    MENU_CATEGORY -> MENU_ITEM -> MEAL_PURCHASE -> INCLUDES
-- =====================================================================

-- Needed for the EXCLUDE constraints that block overlapping date ranges
-- (part of the standard PostgreSQL contrib package).
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ---------------------------------------------------------------------
-- STAFF (superclass + ISA subclasses)
-- ---------------------------------------------------------------------
CREATE TABLE STAFF_MEMBER
(
  staff_id    INT          NOT NULL,
  first_name  VARCHAR(30)  NOT NULL,
  last_name   VARCHAR(30)  NOT NULL,
  phone       VARCHAR(10)  NOT NULL,
  hire_date   DATE         NOT NULL,
  CONSTRAINT pk_staff_member       PRIMARY KEY (staff_id),
  CONSTRAINT uq_staff_phone        UNIQUE (phone),
  CONSTRAINT chk_staff_id          CHECK (staff_id > 0),
  CONSTRAINT chk_staff_first_name  CHECK (first_name ~ '^[[:alpha:]]+([ ''-][[:alpha:]]+)*$'),
  CONSTRAINT chk_staff_last_name   CHECK (last_name  ~ '^[[:alpha:]]+([ ''-][[:alpha:]]+)*$'),
  CONSTRAINT chk_staff_phone       CHECK (phone ~ '^0[0-9]{8,9}$'),
  CONSTRAINT chk_staff_hire_date   CHECK (hire_date BETWEEN DATE '1970-01-01' AND CURRENT_DATE)
);

CREATE TABLE DORM_MANAGER
(
  staff_id         INT          NOT NULL,
  emergency_phone  VARCHAR(10)  NOT NULL,
  CONSTRAINT pk_dorm_manager      PRIMARY KEY (staff_id),
  CONSTRAINT fk_dorm_manager_staff FOREIGN KEY (staff_id)
      REFERENCES STAFF_MEMBER (staff_id) ON DELETE CASCADE,
  CONSTRAINT chk_dm_emergency_phone CHECK (emergency_phone ~ '^0[0-9]{8,9}$')
);

CREATE TABLE CASHIER
(
  staff_id         INT          NOT NULL,
  register_number  INT          NOT NULL,
  shift            VARCHAR(10)  NOT NULL,
  CONSTRAINT pk_cashier            PRIMARY KEY (staff_id),
  CONSTRAINT fk_cashier_staff      FOREIGN KEY (staff_id)
      REFERENCES STAFF_MEMBER (staff_id) ON DELETE CASCADE,
  CONSTRAINT chk_cashier_register  CHECK (register_number BETWEEN 1 AND 50),
  CONSTRAINT chk_cashier_shift     CHECK (shift IN ('morning', 'evening', 'night'))
);

-- ---------------------------------------------------------------------
-- STUDENT
-- ---------------------------------------------------------------------
CREATE TABLE STUDENT
(
  student_id  INT           NOT NULL,
  first_name  VARCHAR(30)   NOT NULL,
  last_name   VARCHAR(30)   NOT NULL,
  phone       VARCHAR(10)   NOT NULL,
  email       VARCHAR(100)  NOT NULL,
  birth_date  DATE          NOT NULL,
  CONSTRAINT pk_student              PRIMARY KEY (student_id),
  CONSTRAINT uq_student_phone        UNIQUE (phone),
  CONSTRAINT uq_student_email        UNIQUE (email),
  CONSTRAINT chk_student_id          CHECK (student_id > 0),
  CONSTRAINT chk_student_first_name  CHECK (first_name ~ '^[[:alpha:]]+([ ''-][[:alpha:]]+)*$'),
  CONSTRAINT chk_student_last_name   CHECK (last_name  ~ '^[[:alpha:]]+([ ''-][[:alpha:]]+)*$'),
  CONSTRAINT chk_student_phone       CHECK (phone ~ '^0[0-9]{8,9}$'),
  CONSTRAINT chk_student_email       CHECK (email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),
  -- a student is at least 16 years old and was born after 1940
  CONSTRAINT chk_student_birth_date  CHECK (birth_date >= DATE '1940-01-01'
                                            AND birth_date <= CURRENT_DATE - INTERVAL '16 years')
);

-- ---------------------------------------------------------------------
-- DORMITORIES
-- ---------------------------------------------------------------------
CREATE TABLE BUILDING
(
  building_id    INT          NOT NULL,
  building_name  VARCHAR(50)  NOT NULL,
  campus         VARCHAR(50)  NOT NULL,
  num_floors     INT          NOT NULL,
  manager_id     INT          NOT NULL,          -- relationship "manages" (1:N)
  CONSTRAINT pk_building           PRIMARY KEY (building_id),
  CONSTRAINT uq_building_name      UNIQUE (campus, building_name),
  CONSTRAINT fk_building_manager   FOREIGN KEY (manager_id)
      REFERENCES DORM_MANAGER (staff_id) ON DELETE RESTRICT,
  CONSTRAINT chk_building_id       CHECK (building_id > 0),
  CONSTRAINT chk_building_floors   CHECK (num_floors BETWEEN 1 AND 30)
);

CREATE TABLE ROOM_TYPE
(
  room_type_id  INT          NOT NULL,
  type_name     VARCHAR(30)  NOT NULL,
  CONSTRAINT pk_room_type          PRIMARY KEY (room_type_id),
  CONSTRAINT uq_room_type_name     UNIQUE (type_name),
  CONSTRAINT chk_room_type_id      CHECK (room_type_id > 0)
);

-- Weak entity: identified by (building_id, room_number)
CREATE TABLE ROOM
(
  building_id   INT  NOT NULL,                   -- identifying relationship "has_room"
  room_number   INT  NOT NULL,
  floor         INT  NOT NULL,
  capacity      INT  NOT NULL,
  room_type_id  INT  NOT NULL,                   -- relationship "of_type" (N:1)
  CONSTRAINT pk_room               PRIMARY KEY (building_id, room_number),
  CONSTRAINT fk_room_building      FOREIGN KEY (building_id)
      REFERENCES BUILDING (building_id) ON DELETE CASCADE,
  CONSTRAINT fk_room_type          FOREIGN KEY (room_type_id)
      REFERENCES ROOM_TYPE (room_type_id) ON DELETE RESTRICT,
  CONSTRAINT chk_room_number       CHECK (room_number > 0),
  CONSTRAINT chk_room_floor        CHECK (floor BETWEEN 0 AND 30),
  CONSTRAINT chk_room_capacity     CHECK (capacity BETWEEN 1 AND 6)
);

-- M:N relationship STUDENT <-> ROOM with attributes
CREATE TABLE ASSIGNED_TO
(
  student_id    INT           NOT NULL,
  building_id   INT           NOT NULL,
  room_number   INT           NOT NULL,
  start_date    DATE          NOT NULL,
  end_date      DATE          NOT NULL,
  monthly_rent  NUMERIC(7,2)  NOT NULL,
  CONSTRAINT pk_assigned_to        PRIMARY KEY (student_id, building_id, room_number, start_date),
  CONSTRAINT fk_assigned_student   FOREIGN KEY (student_id)
      REFERENCES STUDENT (student_id) ON DELETE RESTRICT,
  CONSTRAINT fk_assigned_room      FOREIGN KEY (building_id, room_number)
      REFERENCES ROOM (building_id, room_number) ON DELETE RESTRICT,
  CONSTRAINT chk_assigned_dates    CHECK (end_date > start_date),
  CONSTRAINT chk_assigned_start    CHECK (start_date >= DATE '2000-01-01'),
  CONSTRAINT chk_assigned_rent     CHECK (monthly_rent > 0 AND monthly_rent <= 10000),
  -- a student cannot live in two rooms during overlapping periods
  CONSTRAINT ex_assigned_no_overlap EXCLUDE USING gist (
      student_id WITH =,
      daterange(start_date, end_date) WITH &&
  )
);

-- ---------------------------------------------------------------------
-- GYM
-- ---------------------------------------------------------------------
CREATE TABLE GYM_MEMBERSHIP
(
  membership_id  INT   NOT NULL,
  start_date     DATE  NOT NULL,
  end_date       DATE  NOT NULL,
  student_id     INT   NOT NULL,                 -- relationship "holds" (1:N)
  CONSTRAINT pk_gym_membership     PRIMARY KEY (membership_id),
  CONSTRAINT fk_gym_student        FOREIGN KEY (student_id)
      REFERENCES STUDENT (student_id) ON DELETE CASCADE,
  CONSTRAINT chk_gym_id            CHECK (membership_id > 0),
  CONSTRAINT chk_gym_dates         CHECK (end_date > start_date),
  CONSTRAINT chk_gym_start         CHECK (start_date >= DATE '2000-01-01'),
  -- a student cannot hold two overlapping memberships
  CONSTRAINT ex_gym_no_overlap     EXCLUDE USING gist (
      student_id WITH =,
      daterange(start_date, end_date) WITH &&
  )
);

-- ---------------------------------------------------------------------
-- TUTORING (student tutors student)
-- ---------------------------------------------------------------------
CREATE TABLE TUTORING_SESSION
(
  session_id    INT           NOT NULL,
  course_name   VARCHAR(60)   NOT NULL,
  session_date  DATE          NOT NULL,
  hours         NUMERIC(3,1)  NOT NULL,
  tutor_id      INT           NOT NULL,          -- relationship "tutors"
  tutee_id      INT           NOT NULL,          -- relationship "is_tutored"
  CONSTRAINT pk_tutoring_session   PRIMARY KEY (session_id),
  CONSTRAINT fk_tutoring_tutor     FOREIGN KEY (tutor_id)
      REFERENCES STUDENT (student_id) ON DELETE RESTRICT,
  CONSTRAINT fk_tutoring_tutee     FOREIGN KEY (tutee_id)
      REFERENCES STUDENT (student_id) ON DELETE RESTRICT,
  CONSTRAINT chk_tutoring_id       CHECK (session_id > 0),
  CONSTRAINT chk_tutoring_course   CHECK (length(trim(course_name)) > 0),
  CONSTRAINT chk_tutoring_hours    CHECK (hours > 0 AND hours <= 8),
  CONSTRAINT chk_tutoring_date     CHECK (session_date >= DATE '2000-01-01'),
  CONSTRAINT chk_tutoring_not_self CHECK (tutor_id <> tutee_id)
);

-- ---------------------------------------------------------------------
-- CAFETERIA
-- ---------------------------------------------------------------------
CREATE TABLE MENU_CATEGORY
(
  category_id    INT          NOT NULL,
  category_name  VARCHAR(30)  NOT NULL,
  CONSTRAINT pk_menu_category      PRIMARY KEY (category_id),
  CONSTRAINT uq_menu_category_name UNIQUE (category_name),
  CONSTRAINT chk_menu_category_id  CHECK (category_id > 0)
);

CREATE TABLE MENU_ITEM
(
  item_id        INT           NOT NULL,
  item_name      VARCHAR(50)   NOT NULL,
  price          NUMERIC(6,2)  NOT NULL,
  is_vegetarian  BOOLEAN       NOT NULL DEFAULT FALSE,
  category_id    INT           NOT NULL,         -- relationship "in_category" (N:1)
  CONSTRAINT pk_menu_item          PRIMARY KEY (item_id),
  CONSTRAINT uq_menu_item_name     UNIQUE (item_name),
  CONSTRAINT fk_menu_item_category FOREIGN KEY (category_id)
      REFERENCES MENU_CATEGORY (category_id) ON DELETE RESTRICT,
  CONSTRAINT chk_menu_item_id      CHECK (item_id > 0),
  CONSTRAINT chk_menu_item_price   CHECK (price > 0 AND price <= 500)
);

CREATE TABLE MEAL_PURCHASE
(
  purchase_id     INT          NOT NULL,
  purchase_date   DATE         NOT NULL DEFAULT CURRENT_DATE,
  payment_method  VARCHAR(20)  NOT NULL,
  student_id      INT          NOT NULL,         -- relationship "buys"  (1:N)
  cashier_id      INT          NOT NULL,         -- relationship "sells" (1:N)
  CONSTRAINT pk_meal_purchase      PRIMARY KEY (purchase_id),
  CONSTRAINT fk_purchase_student   FOREIGN KEY (student_id)
      REFERENCES STUDENT (student_id) ON DELETE RESTRICT,
  CONSTRAINT fk_purchase_cashier   FOREIGN KEY (cashier_id)
      REFERENCES CASHIER (staff_id) ON DELETE RESTRICT,
  CONSTRAINT chk_purchase_id       CHECK (purchase_id > 0),
  CONSTRAINT chk_purchase_date     CHECK (purchase_date BETWEEN DATE '2000-01-01' AND CURRENT_DATE),
  CONSTRAINT chk_purchase_payment  CHECK (payment_method IN ('cash', 'credit_card', 'student_card', 'mobile'))
);

-- M:N relationship MEAL_PURCHASE <-> MENU_ITEM with attribute quantity
CREATE TABLE INCLUDES
(
  purchase_id  INT  NOT NULL,
  item_id      INT  NOT NULL,
  quantity     INT  NOT NULL DEFAULT 1,
  CONSTRAINT pk_includes           PRIMARY KEY (purchase_id, item_id),
  CONSTRAINT fk_includes_purchase  FOREIGN KEY (purchase_id)
      REFERENCES MEAL_PURCHASE (purchase_id) ON DELETE CASCADE,
  CONSTRAINT fk_includes_item      FOREIGN KEY (item_id)
      REFERENCES MENU_ITEM (item_id) ON DELETE RESTRICT,
  CONSTRAINT chk_includes_quantity CHECK (quantity BETWEEN 1 AND 20)
);
