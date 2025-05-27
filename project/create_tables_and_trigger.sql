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