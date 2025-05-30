-- 1. посмотрим какие таблицы у нас есть и сколько в них строк
select 'deceased' as table_name, count(*) as row_count from deceased
union all
select 'funeralagencies', count(*) from funeralagencies
union all
select 'plots', count(*) from plots
union all
select 'graves', count(*) from graves
union all
select 'services', count(*) from services
union all
select 'orders', count(*) from orders;

-- 2. количество различных услуг у каждого агенства
select f.name, count(*) as count_services 
from services s
join funeralagencies f on f.id = s.funeralagency_id 
group by f.name;

-- 3. какой был возраст у погибших
select full_name, extract(year from age(date_dead, date_birthday)) as age_at_death 
from deceased;

-- 4. самые дорогие услуги у каждого агенства
select f.name, max(price) 
from services s
join funeralagencies f on f.id = s.funeralagency_id
group by f.id, f.name;

-- 5. количество умерших по годам
select extract(year from date_dead) as death_year, count(*) as deceased_count
from deceased
group by death_year
order by death_year;

-- 6. средняя стоимость услуг по агенству
select f.name, round(avg(price), 2) as avg_price 
from services s
join funeralagencies f on f.id = s.funeralagency_id 
group by s.funeralagency_id, f.name;

-- 7. умершие в возрасте 75 и более
select *
from deceased
where extract(year from age(date_dead, date_birthday)) >= 75;

-- 8. заказы за последние 10 лет
select *
from orders
where order_date >= current_date - interval '3650 days';

-- 9. средний возраст погибших
select round(avg(extract(year from age(date_dead, date_birthday)))) as avg_age
from deceased
where date_birthday is not null and date_dead is not null;

-- 10. количество могил на каждом участке
select plot_id, count(*) as grave_count
from graves
group by plot_id
order by grave_count desc;

-- 11. участки с более чем 500 могилами
select plot_id, count(*)
from graves
group by plot_id
having count(*) > 500;

-- 12. вывести умерших, у которых нет даты рождения
select *
from deceased
where date_birthday is null;

-- 13. услуги по кремации, отсортированные по цене
select *
from services
where name ilike '%кремация%'
order by price desc;

-- 14. все заявки с null услугой (не выбрано при добавлении)
select *
from orders
where service_id is null;

-- 15. умершие, чьи данные были добавлены без агентства
select *
from deceased
where funeralagency_id is null;

-- 16. представление: усреднённая стоимость услуг по категориям услуг (базовый, премиум и т.д.)
create or replace view avg_service_prices_by_category as
select 
  case
    when name ilike '%баз%' then 'базовый'
    when name ilike '%стандарт%' then 'стандартный'
    when name ilike '%премиум%' then 'премиум'
    when name ilike '%элит%' then 'элитный'
    when name ilike '%социальный%' then 'социальный'
    else 'прочее'
  end as category,
  round(avg(price)) as avg_price
from services
group by category;

select * from avg_service_prices_by_category;

-- 17. количество услуг по статусу
select status, count(*) as count
from orders
group by status;

-- 18. умершие по неизвестной причине
select * 
from deceased
where cause_of_death is null;

-- 19. общее количество услуг и заявок по каждому агентству
select f.name,
       count(distinct s.id) as service_count,
       count(o.id) as order_count
from funeralagencies f
left join services s on f.id = s.funeralagency_id
left join orders o on s.id = o.service_id
group by f.name;

-- 20. суммарная стоимость оказанных услуг (если назначена)
select sum(s.price) as total_earned
from orders o
join services s on o.service_id = s.id;
