/*
Отчет по проектной работе БД

Тема моей проектной работы: зеленоградсоке кладбище
Первый этап проектной работы:
•	Разработать даталогическую модель базы данных в любой доступной вам программе.
•	Разрабатываемая база данных должна содержать не менее 6 таблиц. Минимум одно поле в одной из таблиц должно быть автоматически вычисляемым с помощью триггера. Каждая
•	Таблица обязательно должна содержать ограничения.
Ход выполнения:
Создадим БД:
*/
create database zelenograd_cemetery;

/*
Создадим следующие таблицы: 
Таблицы	Поля
plots (участки)	id, name, direction
graves (могилы)	id, plot_id, latitude, longitude, is_occupied, description
funeralagencies (ритуальные агенства)	id, name, phone, address
deceased (умершие)	id, full_name, date_birthday, date_dead, cause_of_death, grave_id, funeralagency_id
relatives (родственники)	id, full_name, phone, relationship, deceased_id
services (услуги)	id, name, price, type
orders (заказы)	id, service_id, grave_id, order_date, status

variables - вспомогательная таблица с важными координатами, в ней всего 2 записи
*/

/*
Ограничения: 
plots
•	name (not null, check name in ('Центральное', 'Северное'))
• check (direction in ('юг', 'юго-восток', 'восток', 'северо-восток', 'север', 'северо-запад', 'запад', 'юго-запад'))
graves
•	plot_id (foreign key → plots.id)
• latitude numeric check (latitude between -90 and 90),
• longitude numeric check (longitude between -180 and 180)
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
    direction text check (direction in ('юг', 'юго-восток', 'восток', 'северо-восток', 'север', 'северо-запад', 'запад', 'юго-запад'))
);

create table graves(
    id serial primary key,
    plot_id integer references plots(id),
    is_occupied boolean default false,
	latitude numeric check (latitude between -90 and 90),
    longitude numeric check (longitude between -180 and 180),
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
    date_dead date check (date_dead IS NULL OR date_birthday is null or date_dead >= date_birthday),
    cause_of_death text,
    grave_id integer unique references graves(id),
    funeralagency_id integer references funeralagencies(id)
);


create table relatives(
    id serial primary key,
    full_name text not null,
    phone text check(phone ~ '^\+7[0-9]{10}$'),
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

-- Доп таблица с двумя важными координатами
create table variables(
    name varchar(40) not null,
    latitude numeric check (latitude between -90 and 90),
    longitude numeric check (longitude between -180 and 180)
);

insert into variables values 
  ('Центральное', 55.985724, 37.260656), -- Кординаты пераого кладбища
  ('Северное', 55.954110, 37.216786); -- Координаты второго кладбища

-- Создадим триггер, который будет изменять статус занятой могилы, при добавлении нового умершего
--(со свободной на занятую):


create or replace function set_grave_occupied()
returns trigger 
as $$
begin
    update graves
    set is_occupied = true -- вот тут
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

-- Заполняем plots
insert into plots (name, direction) values -- в Зеленограде 2 кладбища (Северное и Центральное),  
('Центральное', 'юг'),                     -- также разделим каждое кладбище на 8 частей 
('Центральное', 'юго-восток'),             -- (ориентировочное положение относительно центра кладбища могилы)
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

-- теперь заполняем могилы

DO $$
DECLARE
  flag RECORD;
  i INTEGER;
BEGIN
  FOR i IN 1..40000 LOOP
    -- Получаем случайную запись из plots + variables
    SELECT p.id AS plot_id, p.direction, v.latitude, v.longitude
    INTO flag
    FROM plots p
    JOIN variables v ON v.name = p.name
    ORDER BY random()
    LIMIT 1;

    -- Вставляем одну запись в graves
    INSERT INTO graves (plot_id, latitude, longitude, description)
    VALUES (
      flag.plot_id,
      round(flag.latitude + (
        CASE flag.direction -- через CASE мы "поднастраиваем координаты" в зависимости от того, в какой части могила
          WHEN 'юг' THEN -0.001 + random() * 0.0005
          WHEN 'север' THEN 0.001 - random() * 0.0005
          WHEN 'юго-восток' THEN -0.001 + random() * 0.0003
          WHEN 'северо-восток' THEN 0.001 - random() * 0.0003
          WHEN 'запад' THEN random() * 0.0004 - 0.0002
          WHEN 'восток' THEN random() * 0.0004 - 0.0002
          WHEN 'северо-запад' THEN 0.001 - random() * 0.0003
          WHEN 'юго-запад' THEN -0.001 + random() * 0.0003
          ELSE 0
        END
      )::numeric, 5),
      round(flag.longitude + (
        CASE flag.direction -- аналогично по долготе
          WHEN 'запад' THEN -0.001 + random() * 0.0005
          WHEN 'восток' THEN 0.001 - random() * 0.0005
          WHEN 'юго-восток' THEN 0.001 - random() * 0.0003
          WHEN 'северо-восток' THEN 0.001 - random() * 0.0003
          WHEN 'север' THEN random() * 0.0004 - 0.0002
          WHEN 'юг' THEN random() * 0.0004 - 0.0002
          WHEN 'северо-запад' THEN -0.001 + random() * 0.0003
          WHEN 'юго-запад' THEN -0.001 + random() * 0.0003
          ELSE 0
        END
      )::numeric, 5),
      'Участок №' || i
    );
  END LOOP;
END $$;


-- агенства
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

-- заполним таблицу погибших
WITH male_names AS ( -- заводим массивы имен, фамилий, отчеств для мужчин и женщин
   SELECT ARRAY[
    'Александр', 'Максим', 'Иван', 'Артём', 'Дмитрий', 'Никита', 'Михаил', 'Даниил',
    'Егор', 'Андрей', 'Сергей', 'Владимир', 'Олег', 'Юрий', 'Константин', 'Павел',
    'Роман', 'Анатолий', 'Виктор', 'Станислав', 'Григорий', 'Борис', 'Тимофей',
    'Лев', 'Аркадий', 'Валентин', 'Геннадий', 'Ярослав', 'Василий', 'Евгений'
  ] AS fnames,
  ARRAY[
    'Иванов', 'Петров', 'Сидоров', 'Кузнецов', 'Смирнов', 'Попов', 'Соколов', 'Михайлов',
    'Новиков', 'Фёдоров', 'Морозов', 'Волков', 'Алексеев', 'Лебедев', 'Козлов', 'Степанов',
    'Орлов', 'Крылов', 'Зайцев', 'Соловьёв', 'Борисов', 'Карпов', 'Григорьев', 'Романов',
    'Семёнов', 'Егоров', 'Павлов', 'Макаров', 'Николаев', 'Сергеев'
  ] AS lnames,
  ARRAY[
    'Александрович', 'Максимович', 'Иванович', 'Артёмович', 'Дмитриевич', 'Никитович',
    'Михайлович', 'Даниилович', 'Егорович', 'Андреевич', 'Сергеевич', 'Владимирович',
    'Николаевич', 'Павлович', 'Викторович', 'Васильевич', 'Олегович', 'Юрьевич',
    'Константинович', 'Евгеньевич', 'Романович', 'Анатольевич', 'Валерьевич',
    'Тимофеевич', 'Львович', 'Геннадьевич', 'Ярославович', 'Станиславович',
    'Борисович', 'Григорьевич'
  ] AS patronymics
),
female_names AS (
  SELECT ARRAY[
    'Анастасия', 'Мария', 'Екатерина', 'Дарья', 'Полина', 'Алина', 'Елена', 'Виктория',
    'Юлия', 'Ксения', 'Ольга', 'Светлана', 'Татьяна', 'Ирина', 'Наталья', 'Марина',
    'Людмила', 'Галина', 'Валентина', 'Нина', 'Зоя', 'Вера', 'Любовь', 'Яна', 'Алёна',
    'Оксана', 'Анна', 'Евгения', 'Лидия', 'Жанна'
  ] AS fnames,
  ARRAY[
    'Иванова', 'Петрова', 'Сидорова', 'Кузнецова', 'Смирнова', 'Попова', 'Соколова',
    'Михайлова', 'Новикова', 'Фёдорова', 'Морозова', 'Волкова', 'Алексеева',
    'Лебедева', 'Козлова', 'Степанова', 'Орлова', 'Крылова', 'Зайцева', 'Соловьёва',
    'Борисова', 'Карпова', 'Григорьева', 'Романова', 'Семёнова', 'Егорова', 'Павлова',
    'Макарова', 'Николаева', 'Сергеева'
  ] AS lnames,
  ARRAY[
    'Александровна', 'Максимовна', 'Ивановна', 'Артёмовна', 'Дмитриевна', 'Никитовна',
    'Михайловна', 'Данииловна', 'Егоровна', 'Андреевна', 'Сергеевна', 'Владимировна',
    'Николаевна', 'Павловна', 'Викторовна', 'Васильевна', 'Олеговна', 'Юрьевна',
    'Константиновна', 'Евгеньевна', 'Романовна', 'Анатольевна', 'Валерьевна',
    'Тимофеевна', 'Львовна', 'Геннадьевна', 'Ярославовна', 'Станиславовна',
    'Борисовна', 'Григорьевна'
  ] AS patronymics
),
free_graves AS ( -- берем свободные могилы
  SELECT id AS grave_id
  FROM graves
  ORDER BY random()
  LIMIT 5433
),
indexed_graves AS ( 
  SELECT row_number() OVER () AS rn, grave_id -- через оконную функцию пронумеровываем последовательно номера могил
  FROM free_graves
),
deceased_data AS ( -- заводим дату смерти
  SELECT 
    s.i AS rn,
    CASE WHEN random() < 0.5 THEN 'male' ELSE 'female' END AS gender,
    b.date_birthday
  FROM generate_series(1, 5433) AS s(i)
  JOIN LATERAL (
    SELECT date '1920-01-01' + (random() * (365 * 100))::int AS date_birthday
  ) b ON true
),
final_data AS (
  SELECT
    d.rn,
    CASE d.gender
      WHEN 'male' THEN -- создаем ФИО
        m.lnames[ceil(random()*array_length(m.lnames,1))::int] || ' ' || 
        m.fnames[ceil(random()*array_length(m.fnames,1))::int] || ' ' ||
        m.patronymics[ceil(random()*array_length(m.patronymics,1))::int]
      ELSE
        f.lnames[ceil(random()*array_length(f.lnames,1))::int] || ' ' ||
        f.fnames[ceil(random()*array_length(f.fnames,1))::int] || ' ' ||
        f.patronymics[ceil(random()*array_length(f.patronymics,1))::int]
    END AS full_name,

    d.date_birthday, -- рождение

    d.date_birthday + (trunc(random() * (CURRENT_DATE - d.date_birthday))::int) AS date_dead, -- смерть

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
    ])[ceil(random()*11)::int] AS cause_of_death -- ну тут понятно

  FROM deceased_data d
  CROSS JOIN male_names m
  CROSS JOIN female_names f
)

INSERT INTO deceased (
  full_name, date_dead, cause_of_death, grave_id
)
SELECT 
  f.full_name,
  f.date_dead,
  f.cause_of_death,
  g.grave_id
FROM final_data f
JOIN indexed_graves g ON f.rn = g.rn;

DO $$
BEGIN -- там хреново заводилось рождение (у всех одинаковое, исправим это)
  UPDATE deceased
  SET date_birthday = date_dead - ((random() * 36500)::int)
  WHERE date_birthday IS NULL
    AND date_dead IS NOT NULL;
END
$$;

DO $$
DECLARE -- заполним агенство, которое занималось захоранением
  r RECORD;
  random_agency_id INTEGER;
BEGIN
  FOR r IN SELECT id FROM deceased
  LOOP
    SELECT id INTO random_agency_id
    FROM funeralagencies
    ORDER BY random()
    LIMIT 1;

    UPDATE deceased
    SET funeralagency_id = random_agency_id
    WHERE id = r.id;
  END LOOP;
END $$;



-- теперь таблицу родственников

WITH male_names AS ( -- тоже самое
   SELECT ARRAY[
    'Александр', 'Максим', 'Иван', 'Артём', 'Дмитрий', 'Никита', 'Михаил', 'Даниил',
    'Егор', 'Андрей', 'Сергей', 'Владимир', 'Олег', 'Юрий', 'Константин', 'Павел',
    'Роман', 'Анатолий', 'Виктор', 'Станислав', 'Григорий', 'Борис', 'Тимофей',
    'Лев', 'Аркадий', 'Валентин', 'Геннадий', 'Ярослав', 'Василий', 'Евгений'
  ] AS fnames,
  ARRAY[
    'Иванов', 'Петров', 'Сидоров', 'Кузнецов', 'Смирнов', 'Попов', 'Соколов', 'Михайлов',
    'Новиков', 'Фёдоров', 'Морозов', 'Волков', 'Алексеев', 'Лебедев', 'Козлов', 'Степанов',
    'Орлов', 'Крылов', 'Зайцев', 'Соловьёв', 'Борисов', 'Карпов', 'Григорьев', 'Романов',
    'Семёнов', 'Егоров', 'Павлов', 'Макаров', 'Николаев', 'Сергеев'
  ] AS lnames,
  ARRAY[
    'Александрович', 'Максимович', 'Иванович', 'Артёмович', 'Дмитриевич', 'Никитович',
    'Михайлович', 'Даниилович', 'Егорович', 'Андреевич', 'Сергеевич', 'Владимирович',
    'Николаевич', 'Павлович', 'Викторович', 'Васильевич', 'Олегович', 'Юрьевич',
    'Константинович', 'Евгеньевич', 'Романович', 'Анатольевич', 'Валерьевич',
    'Тимофеевич', 'Львович', 'Геннадьевич', 'Ярославович', 'Станиславович',
    'Борисович', 'Григорьевич'
  ] AS patronymics
),
female_names AS (
  SELECT ARRAY[
    'Анастасия', 'Мария', 'Екатерина', 'Дарья', 'Полина', 'Алина', 'Елена', 'Виктория',
    'Юлия', 'Ксения', 'Ольга', 'Светлана', 'Татьяна', 'Ирина', 'Наталья', 'Марина',
    'Людмила', 'Галина', 'Валентина', 'Нина', 'Зоя', 'Вера', 'Любовь', 'Яна', 'Алёна',
    'Оксана', 'Анна', 'Евгения', 'Лидия', 'Жанна'
  ] AS fnames,
  ARRAY[
    'Иванова', 'Петрова', 'Сидорова', 'Кузнецова', 'Смирнова', 'Попова', 'Соколова',
    'Михайлова', 'Новикова', 'Фёдорова', 'Морозова', 'Волкова', 'Алексеева',
    'Лебедева', 'Козлова', 'Степанова', 'Орлова', 'Крылова', 'Зайцева', 'Соловьёва',
    'Борисова', 'Карпова', 'Григорьева', 'Романова', 'Семёнова', 'Егорова', 'Павлова',
    'Макарова', 'Николаева', 'Сергеева'
  ] AS lnames,
  ARRAY[
    'Александровна', 'Максимовна', 'Ивановна', 'Артёмовна', 'Дмитриевна', 'Никитовна',
    'Михайловна', 'Данииловна', 'Егоровна', 'Андреевна', 'Сергеевна', 'Владимировна',
    'Николаевна', 'Павловна', 'Викторовна', 'Васильевна', 'Олеговна', 'Юрьевна',
    'Константиновна', 'Евгеньевна', 'Романовна', 'Анатольевна', 'Валерьевна',
    'Тимофеевна', 'Львовна', 'Геннадьевна', 'Ярославовна', 'Станиславовна',
    'Борисовна', 'Григорьевна'
  ] AS patronymics
),
relationships AS (
  SELECT * FROM (
    VALUES 
      ('мать', 'female'),
      ('отец', 'male'),
      ('дочь', 'female'),
      ('сын', 'male'),
      ('брат', 'male'),
      ('сестра', 'female'),
      ('дед', 'male'),
      ('бабушка', 'female'),
      ('внук', 'male'),
      ('внучка', 'female'),
      ('муж', 'male'),
      ('жена', 'female')
  ) AS rel(relationship, gender)
),
random_deceased AS (
  SELECT id FROM deceased ORDER BY random() LIMIT 7243
)

INSERT INTO relatives (full_name, phone, relationship, deceased_id) --
SELECT 
  CASE r.gender
    WHEN 'male' THEN 
      m.lnames[ceil(random() * array_length(m.lnames, 1))::int] || ' ' ||
      m.fnames[ceil(random() * array_length(m.fnames, 1))::int] || ' ' ||
      m.patronymics[ceil(random() * array_length(m.patronymics, 1))::int]
    ELSE 
      f.lnames[ceil(random() * array_length(f.lnames, 1))::int] || ' ' ||
      f.fnames[ceil(random() * array_length(f.fnames, 1))::int] || ' ' ||
      f.patronymics[ceil(random() * array_length(f.patronymics, 1))::int]
  END AS full_name,

  '+7' || lpad((trunc(random() * 1e10))::bigint::text, 10, '0') AS phone,
  r.relationship,
  d.id AS deceased_id

FROM random_deceased d
JOIN LATERAL (SELECT * FROM relationships ORDER BY random() LIMIT 1) r ON true
CROSS JOIN male_names m
CROSS JOIN female_names f;

-- заполняем таблицу услуг
INSERT INTO services (name, price, type) VALUES
  ('Организация похорон', 15000.00, 'похоронные'),
  ('Транспортировка тела', 8000.00, 'ритуальные'),
  ('Установка памятника', 25000.00, 'дополнительные'),
  ('Оформление документов', 3000.00, 'административные'),
  ('Ритуальный транспорт (катафалк)', 12000.00, 'ритуальные'),
  ('Услуги носильщиков', 4000.00, 'ритуальные'),
  ('Кремация', 10000.00, 'похоронные'),
  ('Бальзамирование', 7000.00, 'медицинские'),
  ('Подготовка тела (омывание, одевание)', 5000.00, 'медицинские'),
  ('Аренда зала прощания', 6000.00, 'дополнительные'),
  ('Изготовление гроба', 9000.00, 'ритуальные'),
  ('Цветочное оформление', 3500.00, 'дополнительные');

-- заполняем таблицу заявок
DO $$
DECLARE
  i INT;
  random_service_id INT;
  random_grave_id INT;
  death_date DATE;
  random_order_date DATE;
  status_list TEXT[] := ARRAY['выполнен', 'отменен', 'в процессе', 'ожидает оплаты']; 
  random_status TEXT;
BEGIN
  FOR i IN 1..9000 LOOP
    -- Получаем случайный service_id
    SELECT id INTO random_service_id FROM services ORDER BY random() LIMIT 1;

    -- Получаем случайный grave_id и дату смерти, связанного с ним deceased
    SELECT g.id, d.date_dead
    INTO random_grave_id, death_date
    FROM graves g
    JOIN deceased d ON d.grave_id = g.id
    WHERE d.date_dead IS NOT NULL
    ORDER BY random()
    LIMIT 1;

    -- Выбираем дату заказа ±30 дней от даты смерти
    random_order_date := death_date + (trunc(random() * 61) - 30)::int; 

    -- Выбираем случайный статус
    random_status := status_list[ceil(random() * array_length(status_list, 1))::int];

    -- Вставляем запись
    INSERT INTO orders (service_id, grave_id, order_date, status)
    VALUES (random_service_id, random_grave_id, random_order_date, random_status);
  END LOOP;
END $$;
