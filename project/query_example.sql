-- 1. Посмотрим какие таблицы у нас есть и сколько в них строк

SELECT 'deceased' AS table_name, COUNT(*) AS row_count FROM deceased
UNION ALL
SELECT 'relatives', COUNT(*) FROM relatives
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

-- 2. Посмотрим сколько могил в каком кладбище

create temp table temp_table(
	name_cementery text,
	count_graves integer
);

insert into temp_table values
('Всего могил', (select count(*) from graves)),
('Центральное', (select count(*) from graves where 55.98 = round(latitude, 2))),
('Северное', (select count(*) from graves where 55.98 <> round(latitude, 2)));

select * from temp_table;

-- 3. Найдем топ 5 услуг

SELECT s.name, COUNT(*) AS order_count
FROM orders o
JOIN services s ON o.service_id = s.id
GROUP BY s.name
ORDER BY order_count DESC
LIMIT 5;

-- 4. Найдем всех родственников определенного типа

SELECT r.full_name, r.phone, d.full_name AS deceased
FROM relatives r
JOIN deceased d ON r.deceased_id = d.id
WHERE r.relationship = 'мать';

-- 5. Посмотрим сколько погибших захоронило какое агенств

select count(*) as count_orders, f.name from deceased d 
join funeralagencies f on d.funeralagency_id = f.id 
group by d.funeralagency_id, f.name 
order by count_orders;

-- 6 Количество умерших по годам

SELECT EXTRACT(YEAR FROM date_death) AS death_year, COUNT(*) AS deceased_count
FROM deceased
GROUP BY death_year
ORDER BY death_year;

-- 7 Средняя стоимость услуг по типу

SELECT type, ROUND(AVG(price), 2) AS avg_price
FROM services
GROUP BY type;

-- 8 родственники у которых более одного умершего

SELECT r.full_name, COUNT(*) AS deceased_count
FROM relatives r
GROUP BY r.full_name
HAVING COUNT(*) > 1
ORDER BY deceased_count DESC;

-- 9 количество услуг на могилу

SELECT g.id AS grave_id, COUNT(o.id) AS order_count
FROM graves g
LEFT JOIN orders o ON g.id = o.grave_id
where g.id = 20427
GROUP BY g.id;

-- 10 Количество услуг на одного из родственников

SELECT r.full_name, COUNT(o.id) AS orders_count
FROM relatives r
JOIN deceased d ON r.deceased_id = d.id
JOIN graves g ON d.grave_id = g.id
JOIN orders o ON o.grave_id = g.id
GROUP BY r.full_name
ORDER BY orders_count DESC;

-- 11 Топ 20 самых дорогих заохоронений

select sum(s.price) as total_price, d.full_name
from deceased d 
join graves g on d.grave_id = g.id
join orders r on r.grave_id = g.id
join services s on s.id = r.service_id
group by g.id, d.full_name
order by total_price desc
limit 20;

-- 12 количество услуг по типу

SELECT s.type, COUNT(*) AS order_count
FROM orders o
JOIN services s ON o.service_id = s.id
GROUP BY s.type;

-- 13 Погибшие для которых заказывали установку памятника

SELECT DISTINCT d.*
FROM deceased d
JOIN orders o ON o.grave_id = d.grave_id
JOIN services s ON s.id = o.service_id
WHERE s.name = 'Установка памятника';

-- 14 Общая выручка по услуге

SELECT s.name, SUM(s.price) AS total_revenue
FROM orders o
JOIN services s ON s.id = o.service_id
GROUP BY s.name
ORDER BY total_revenue DESC;

-- 15 Умершие в возрасте 95 и более

SELECT *
FROM deceased
WHERE EXTRACT(YEAR FROM age(date_dead, date_birthday)) >= 95;

-- 16 Количество погибших на каждом участке

SELECT plot_id, COUNT(*) AS graves_count
FROM graves
GROUP BY plot_id
ORDER BY graves_count DESC;

-- 17 Заказы за последние 30 дней

SELECT *
FROM orders
WHERE order_date >= current_date - INTERVAL '30 days';

-- 18 Погибшие без родственников

SELECT d.*
FROM deceased d
LEFT JOIN relatives r ON r.deceased_id = d.id
WHERE r.id IS NULL;

-- 19 Средний возраст погибших

SELECT ROUND(AVG(EXTRACT(YEAR FROM age(date_dead, date_birthday)))) AS avg_age
FROM deceased
WHERE date_birthday IS NOT NULL AND date_dead IS NOT NULL;

--20 Количество услуг на могилу (у которых более одной услуги)

SELECT grave_id, COUNT(*) AS orders_count
FROM orders
GROUP BY grave_id
HAVING COUNT(*) > 1
order by orders_count desc;

