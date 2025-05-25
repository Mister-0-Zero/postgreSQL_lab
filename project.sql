/*
Отчет по проектной работе БД

Тема моей проектной работы: зеленоградсоке кладбище
Первый этап проектной работы:
•	Разработать даталогическую модель базы данных в любой доступной вам программе.
•	Разрабатываемая база данных должна содержать не менее 6 таблиц. Минимум одно поле в одной из таблиц должно быть автоматически вычисляемым с помощью триггера. Каждая
•	Таблица обязательно должна содержать ограничения.
Ход выполнения:
Создадим следующие таблицы: 
Таблицы	Поля
plots (участки)	id, name, direction
graves (могилы)	id, plot_id, latitude, longitude, is_occupied, description
funeralagencies (ритуальные агенства)	id, name, phone, address
deceased (умершие)	id, full_name, date_birthday, date_dead, cause_of_death, grave_id, funeralagency_id
relatives (родственники)	id, full_name, phone, relationship, deceased_id
services (услуги)	id, name, price, type
orders (заказы)	id, service_id, grave_id, order_date, status
*/

/*
Ограничения: 
plots
•	name (not null, check name in ('Центральное', 'Северное'))
•   check (direction in ('юг', 'юго-восток', 'восток', 'северо-восток', 'север', 'северо-запад', 'запад', 'юго-запад'))
graves
•	plot_id (foreign key → plots.id)
•	latitude (check between -90 and 90)
•	longitude (check between -180 and 180)
•	is_occupied (default false)
funeralagencies
•	name (unique, not null)
•	phone (check matches regex '^\+?[0-9]{5,11}$')
deceased
•	full_name (not null)
•	date_dead (check date_dead is null or date_dead > date_birthday)
•	grave_id (unique, foreign key → graves.id)
•	funeralagency_id (foreign key → funeralagencies.id)
relatives
•	full_name (not null)
•	phone (check matches regex '^\+?[0-9]{11}$')
•	deceased_id (foreign key → deceased.id)
services
•	name (not null)
•	price (not null, check price > 0)
orders
•	service_id (foreign key → services.id)
•	grave_id (foreign key → graves.id)
•	order_date (default current_date)
•	status (not null)
*/

--Итоговый код:
create table plots(
    id serial primary key,
    name text not null check (name in ('Центральное', 'Северное')),
    direction text check (direction in ('юг', 'юго-восток', 'восток', 'северо-восток', 'север', 'северо-запад', 'запад', 'юго-запад')),
    lat_base numeric,
    lon_base numeric
);

create table graves(
    id serial primary key,
    plot_id integer references plots(id),
    latitude numeric check (latitude between -90 and 90),
    longitude numeric check (longitude between -180 and 180),
    is_occupied boolean default false,
    description text
);

create table funeralagencies(
    id serial primary key,
    name text unique not null,
    phone text not null check(phone ~ '^\+?[0-9]{5,12}$'),
    address text
);


create table deceased (
    id serial primary key,
    full_name varchar(40) not null,
    date_birthday date,
    date_dead date check (date_dead IS NULL OR date_birthday is null or date_dead > date_birthday),
    cause_of_death text,
    grave_id integer unique references graves(id),
    funeralagency_id integer references funeralagencies(id)
);


create table relatives(
    id serial primary key,
    full_name text not null,
    phone text check(phone ~ '^\\+?[0-9]{11}$'),
    relationship text,
    deceased_id integer references deceased(id)
);


create table services(
    id serial primary key,
    name text not null,
    price numeric not null check(price > 0),
    type text
);


create table orders(
    id serial primary key,
    service_id integer references services(id),
    grave_id integer references graves(id),
    order_date date default current_date,
    status text not null
);


-- Создадим триггер, который будет изменять статус занятой могилы, при добавлении нового умершего:


create or replace function set_grave_occupied()
returns trigger 
as $$
begin
    update graves
    set is_occupied = true
    where id = new.grave_id;
    return new;
end;
$$ language plpgsql;

create trigger trg_set_grave_occupied
after insert on deceased	
for each row
when (new.grave_id is not null)
execute procedure set_grave_occupied();

/*
Этап 2 Создать базу данных в СУБД PostgreSQL. Заполнить таблицы данными (Не менее 10
записей в каждой из таблиц). Составить не менее 20 осмысленных, разнообразных запросов к
базе данных. Часть из них возможно оформить в виде представлений.
*/

insert into plots (name, direction) values
('Центральное', 'юг'),
('Центральное', 'юго-восток'),
('Центральное', 'восток'),
('Центральное', 'северо-восток'),
('Центральное', 'север'),
('Центральное', 'северо-запад'),
('Центральное', 'запад'),
('Центральное', 'юго-запад'),
('Северное', 'юг'),
('Северное', 'юго-восток'),
('Северное', 'восток'),
('Северное', 'северо-восток'),
('Северное', 'север'),
('Северное', 'северо-запад'),
('Северное', 'запад'),
('Северное', 'юго-запад');

update plots
set lat_base = 55.985724, lon_base = 37.260656
where name = 'Центральное';

update plots
set lat_base = 55.954110, lon_base = 37.216786
where name = 'Северное';

insert into graves (plot_id, latitude, longitude, description)
select
  p.id,
  p.lat_base + (
    case p.direction
      when 'юг' then -0.001 + random() * 0.0005
      when 'север' then 0.001 - random() * 0.0005
      when 'юго-восток' then -0.001 + random() * 0.0003
      when 'северо-восток' then 0.001 - random() * 0.0003
      when 'запад' then random() * 0.0004 - 0.0002
      when 'восток' then random() * 0.0004 - 0.0002
      when 'северо-запад' then 0.001 - random() * 0.0003
      when 'юго-запад' then -0.001 + random() * 0.0003
    end
  ),
  p.lon_base + (
    case p.direction
      when 'запад' then -0.001 + random() * 0.0005
      when 'восток' then 0.001 - random() * 0.0005
      when 'юго-восток' then 0.001 - random() * 0.0003
      when 'северо-восток' then 0.001 - random() * 0.0003
      when 'север' then random() * 0.0004 - 0.0002
      when 'юг' then random() * 0.0004 - 0.0002
      when 'северо-запад' then -0.001 + random() * 0.0003
      when 'юго-запад' then -0.001 + random() * 0.0003
    end
  ),
  'Участок №' || s.id
from
  generate_series(1, 100000) as s(id)
  join plots as p on true;


INSERT INTO funeralagencies (name, phone, address)
VALUES
  ('Ритуал-Сервис', '+74951234567', 'г. Зеленоград, ул. Центральная, д. 1'),
  ('Покой и Свет', '84957778888', 'г. Зеленоград, ул. Юности, д. 5'),
  ('Вечная Память', '+79161234567', 'г. Зеленоград, ул. Панфилова, д. 10'),
  ('Реквием', '84957654321', 'г. Зеленоград, ул. Георгиевская, д. 2'),
  ('Зеленградский обряд', '+74959876543', 'г. Зеленоград, просп. Генерала Алексеева, д. 7'),
  ('Память Зеленограда', '89163456789', 'г. Зеленоград, ул. Каменка, д. 14'),
  ('Спокойствие', '+74951112233', 'г. Зеленоград, ул. Савелкинская, д. 3'),
  ('Честный Ритуал', '84959998877', 'г. Зеленоград, ул. Андреевка, д. 6'),
  ('Мемориал-Сервис', '+79260000001', 'г. Зеленоград, ул. Конструктора Лукина, д. 9'),
  ('Горсервис', '84958887766', 'г. Зеленоград, ул. Солнечная аллея, д. 12');

  WITH names AS (
  SELECT ARRAY[
	  'Александр', 'Максим', 'Иван', 'Артём', 'Дмитрий', 'Никита', 'Михаил', 'Даниил', 'Егор', 'Андрей',
	  'Анастасия', 'Мария', 'Екатерина', 'Дарья', 'Полина', 'Алина', 'Елена', 'Виктория', 'Юлия', 'Ксения',
	  'Ольга', 'Светлана', 'Татьяна', 'Ирина', 'Наталья', 'Марина', 'Людмила', 'Галина', 'Валентина', 'Нина'
	] AS fnames,
  ARRAY[
	  'Иванов', 'Петров', 'Сидоров', 'Кузнецов', 'Смирнов', 'Попов', 'Соколов', 'Михайлов', 'Новиков', 'Федоров',
	  'Морозов', 'Волков', 'Алексеев', 'Лебедев', 'Козлов', 'Степанов', 'Орлов', 'Крылов', 'Зайцев', 'Соловьёв',
	  'Борисов', 'Карпов', 'Григорьев', 'Романов', 'Семенов', 'Егоров', 'Павлов', 'Макаров', 'Николаев', 'Сергеев'
	] AS lnames,
  ARRAY[
	  'Александрович', 'Максимович', 'Иванович', 'Артёмович', 'Дмитриевич', 'Никитович', 'Михайлович', 'Даниилович', 'Егорович', 'Андреевич',
	  'Сергеевич', 'Владимирович', 'Николаевич', 'Павлович', 'Викторович', 'Васильевич', 'Олегович', 'Юрьевич', 'Константинович', 'Евгеньевич',
	  'Александровна', 'Максимовна', 'Ивановна', 'Артёмовна', 'Дмитриевна', 'Никитовна', 'Михайловна', 'Данииловна', 'Егоровна', 'Андреевна',
	  'Сергеевна', 'Владимировна', 'Николаевна', 'Павловна', 'Викторовна', 'Васильевна', 'Олеговна', 'Юрьевна', 'Константиновна', 'Евгеньевна'
	] AS patronymics
),

free_graves AS (
  SELECT id AS grave_id FROM graves
  order by random()
  LIMIT 5433
),

inserted AS (
  INSERT INTO deceased (full_name, date_birthday, date_dead, cause_of_death, grave_id, funeralagency_id)
  SELECT
    -- ФИО: случайное имя + фамилия
    (fnames[ceil(random()*array_length(fnames,1))::int] || ' ' || 
     lnames[ceil(random()*array_length(lnames,1))::int]  || ' ' || 
	 patronymics[ceil(random()*array_length(patronymics,1))::int]) AS full_name,

    -- Дата рождения: между 1920-01-01 и 2020-01-01
    d.date_birthday,

    -- Дата смерти: между датой рождения и сегодня
    d.date_birthday + ((random() * (CURRENT_DATE - d.date_birthday))::int),
    
    -- Причина смерти
    (ARRAY[
		  'естественная смерть',
		  'болезнь',
		  'ДТП',
		  'несчастный случай',
		  'сердечный приступ',
		  'инфаркт',
		  'инсульт',
		  'отравление',
		  'пожар',
		  'убийство',
		  NULL
	])[ceil(random()*11)::int],

    -- Случайный grave_id из свободных
    g.grave_id,

    -- Случайное агенство
    (SELECT id FROM funeralagencies ORDER BY random() LIMIT 1)

  FROM generate_series(1, 5433) AS s(id)
  CROSS JOIN names
  JOIN LATERAL (
    SELECT date '1920-01-01' + (random() * (365 * 100))::int AS date_birthday
  ) AS d ON true
  JOIN free_graves AS g ON g.grave_id IS NOT NULL
  LIMIT 5433
  RETURNING grave_id
)

SELECT count(*) FROM inserted;