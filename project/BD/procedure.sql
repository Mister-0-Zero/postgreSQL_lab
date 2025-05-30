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
  SELECT s.name, COUNT(o.id) AS order_count
  FROM services s
  LEFT JOIN orders o ON o.service_id = s.id
  GROUP BY s.name;
END;
$$;

-- Очистить все таблицы в нужном порядке (с учетом внешних ключей)
CREATE OR REPLACE PROCEDURE clear_all_data()
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM orders;
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
  v_grave_id INTEGER;
  v_service_id INTEGER;
  v_date_dead DATE;
  v_funeralagency_id INTEGER;
BEGIN
  SELECT grave_id, date_dead, funeralagency_id 
  INTO v_grave_id, v_date_dead, v_funeralagency_id
  FROM deceased
  WHERE id = p_deceased_id;

  IF v_grave_id IS NULL THEN
    RAISE NOTICE 'Нет могилы у умершего %', p_deceased_id;
    RETURN;
  END IF;

  -- Ищем услугу захоронения у того же агентства, что и умерший
  SELECT id INTO v_service_id 
  FROM services 
  WHERE funeralagency_id = v_funeralagency_id 
    AND LOWER(name) LIKE '%захоронение%' 
  LIMIT 1;

  IF v_service_id IS NOT NULL THEN
    INSERT INTO orders(service_id, grave_id, order_date, status)
    VALUES (v_service_id, v_grave_id, COALESCE(v_date_dead, CURRENT_DATE), 'выполнено');
  ELSE
    RAISE NOTICE 'Не найдена услуга захоронения для агентства %', v_funeralagency_id;
  END IF;
END;
$$;

-- Освобождение могилы

CREATE OR REPLACE PROCEDURE mark_grave_as_available(grave_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Помечаем могилу как свободную
    UPDATE graves SET is_occupied = false WHERE id = grave_id;
    
    -- Удаляем связь с умершим
    UPDATE deceased SET grave_id = NULL WHERE grave_id = grave_id;
    
    RAISE NOTICE 'Могила % освобождена', grave_id;
END;
$$;