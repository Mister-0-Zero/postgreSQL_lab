# Примеры SQL запросов для базы данных "Зеленоградское кладбище"

## Основные информационные запросы

### 1. Количество записей в таблицах
```sql
-- Посмотрим какие таблицы у нас есть и сколько в них строк
SELECT 'deceased' AS table_name, COUNT(*) AS row_count FROM deceased
UNION ALL
SELECT 'funeralagencies', COUNT(*) FROM funeralagencies
UNION ALL
SELECT 'plots', COUNT(*) FROM plots
UNION ALL
SELECT 'graves', COUNT(*) FROM graves
UNION ALL
SELECT 'services', COUNT(*) FROM services
UNION ALL
SELECT 'orders', COUNT(*) FROM orders;
```

### 2. Количество услуг по агентствам
```sql
SELECT f.name, COUNT(*) AS count_services 
FROM services s
JOIN funeralagencies f ON f.id = s.funeralagency_id 
GROUP BY f.name;
```

### 3. Возраст умерших
```sql
SELECT full_name, EXTRACT(YEAR FROM AGE(date_dead, date_birthday)) AS age_at_death 
FROM deceased;
```

## Аналитические запросы

### 4. Самые дорогие услуги по агентствам
```sql
SELECT f.name, MAX(price) 
FROM services s
JOIN funeralagencies f ON f.id = s.funeralagency_id
GROUP BY f.id, f.name;
```

### 5. Количество умерших по годам
```sql
SELECT EXTRACT(YEAR FROM date_dead) AS death_year, COUNT(*) AS deceased_count
FROM deceased
GROUP BY death_year
ORDER BY death_year;
```

### 6. Средняя стоимость услуг
```sql
SELECT f.name, ROUND(AVG(price), 2) AS avg_price 
FROM services s
JOIN funeralagencies f ON f.id = s.funeralagency_id 
GROUP BY s.funeralagency_id, f.name;
```

## Специальные запросы

### 7. Умершие в возрасте 75+
```sql
SELECT *
FROM deceased
WHERE EXTRACT(YEAR FROM AGE(date_dead, date_birthday)) >= 75;
```

### 8. Заказы за последние 10 лет
```sql
SELECT *
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '3650 days';
```

### 9. Средний возраст умерших
```sql
SELECT ROUND(AVG(EXTRACT(YEAR FROM AGE(date_dead, date_birthday)))) AS avg_age
FROM deceased
WHERE date_birthday IS NOT NULL AND date_dead IS NOT NULL;
```

### 10. Количество могил по участкам
```sql
SELECT plot_id, COUNT(*) AS grave_count
FROM graves
GROUP BY plot_id
ORDER BY grave_count DESC;
```

## Проверочные запросы

### 11. Участки с >500 могилами
```sql
SELECT plot_id, COUNT(*)
FROM graves
GROUP BY plot_id
HAVING COUNT(*) > 500;
```

### 12. Умершие без даты рождения
```sql
SELECT *
FROM deceased
WHERE date_birthday IS NULL;
```

### 13. Услуги по кремации
```sql
SELECT *
FROM services
WHERE name ILIKE '%кремация%'
ORDER BY price DESC;
```

### 14. Заявки без указания услуги
```sql
SELECT *
FROM orders
WHERE service_id IS NULL;
```

### 15. Умершие без указания агентства
```sql
SELECT *
FROM deceased
WHERE funeralagency_id IS NULL;
```

## Сложные запросы

### 16. Представление: средние цены по категориям
```sql
CREATE OR REPLACE VIEW avg_service_prices_by_category AS
SELECT 
  CASE
    WHEN name ILIKE '%баз%' THEN 'базовый'
    WHEN name ILIKE '%стандарт%' THEN 'стандартный'
    WHEN name ILIKE '%премиум%' THEN 'премиум'
    WHEN name ILIKE '%элит%' THEN 'элитный'
    WHEN name ILIKE '%социальный%' THEN 'социальный'
    ELSE 'прочее'
  END AS category,
  ROUND(AVG(price)) AS avg_price
FROM services
GROUP BY category;

SELECT * FROM avg_service_prices_by_category;
```

### 17. Статистика по статусам заказов
```sql
SELECT status, COUNT(*) AS count
FROM orders
GROUP BY status;
```

### 18. Умершие с неизвестной причиной смерти
```sql
SELECT * 
FROM deceased
WHERE cause_of_death IS NULL;
```

### 19. Агентства с количеством услуг и заказов
```sql
SELECT f.name,
       COUNT(DISTINCT s.id) AS service_count,
       COUNT(o.id) AS order_count
FROM funeralagencies f
LEFT JOIN services s ON f.id = s.funeralagency_id
LEFT JOIN orders o ON s.id = o.service_id
GROUP BY f.name;
```

### 20. Общая выручка
```sql
SELECT SUM(s.price) AS total_earned
FROM orders o
JOIN services s ON o.service_id = s.id;
```