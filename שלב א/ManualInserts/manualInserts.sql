-- =====================================================================
-- METHOD A - hand-written INSERT statements
-- Core lookup rows, written manually. The Python generator (method B)
-- adds more rows to these tables, starting from the next free id.
-- =====================================================================

INSERT INTO MENU_CATEGORY (category_id, category_name) VALUES
  (1,  'Breakfast'),
  (2,  'Main Course'),
  (3,  'Salads'),
  (4,  'Soups'),
  (5,  'Sandwiches'),
  (6,  'Pasta'),
  (7,  'Grill'),
  (8,  'Side Dishes'),
  (9,  'Desserts'),
  (10, 'Hot Drinks'),
  (11, 'Cold Drinks'),
  (12, 'Snacks');
