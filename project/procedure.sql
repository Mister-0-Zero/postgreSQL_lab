-- Добавление нового родственника по ID умершего

CREATE OR REPLACE PROCEDURE add_random_relative(p_deceased_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
  fname TEXT := 'Иван';
  lname TEXT := 'Иванов';
  patronymic TEXT := 'Иванович';
  full_name TEXT;
  phone TEXT := '+7' || lpad((trunc(random() * 1e10))::bigint::text, 10, '0');
  relationship TEXT := 'брат';
BEGIN
  full_name := lname || ' ' || fname || ' ' || patronymic;

  INSERT INTO relatives (full_name, phone, relationship, deceased_id)
  VALUES (full_name, phone, relationship, p_deceased_id);
END;
$$;

-- Удаление всех заявок, связанных с конкретной могилой

CREATE OR REPLACE PROCEDURE delete_orders_by_grave(p_grave_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM orders WHERE grave_id = p_grave_id;
END;
$$;

-- Показать статистику по количеству заказов на каждую услугу

CREATE OR REPLACE PROCEDURE generate_service_stats()
LANGUAGE plpgsql
AS $$
BEGIN
  DROP TABLE IF EXISTS service_stats;

  CREATE TEMP TABLE service_stats AS
  SELECT s.name, s.type, COUNT(o.id) AS order_count
  FROM services s
  LEFT JOIN orders o ON o.service_id = s.id
  GROUP BY s.name, s.type;
END;
$$;
 
-- Показать статистику по количеству заказов на каждую услугу
CREATE OR REPLACE PROCEDURE generate_service_stats()
LANGUAGE plpgsql
AS $$
BEGIN
  DROP TABLE IF EXISTS service_stats;

  CREATE TEMP TABLE service_stats AS
  SELECT s.name, s.type, COUNT(o.id) AS order_count
  FROM services s
  LEFT JOIN orders o ON o.service_id = s.id
  GROUP BY s.name, s.type;
END;
$$;


-- Очистить все таблицы в нужном порядке
CREATE OR REPLACE PROCEDURE clear_all_data()
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM orders;
  DELETE FROM relatives;
  DELETE FROM deceased;
  DELETE FROM graves;
  DELETE FROM services;
  DELETE FROM funeralagencies;
  DELETE FROM plots;
END;
$$;

-- Автоматическая генерация заявки на "захоронение" по умершему
CREATE OR REPLACE PROCEDURE create_burial_order(p_deceased_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
  grave INTEGER;
  service_id INTEGER;
  death_date DATE;
BEGIN
  SELECT grave_id, date_death INTO grave, death_date
  FROM deceased
  WHERE id = p_deceased_id;

  IF grave IS NULL THEN
    RAISE NOTICE 'Нет могилы у умершего %', p_deceased_id;
    RETURN;
  END IF;

  SELECT id INTO service_id FROM services WHERE LOWER(type) = 'захоронение' LIMIT 1;

  IF service_id IS NOT NULL THEN
    INSERT INTO orders(service_id, grave_id, order_date, status)
    VALUES (service_id, grave, death_date, 'выполнено');
  END IF;
END;
$$;