create table plots(
    id serial primary key,
    name text not null,
    latitude numeric check (latitude between -90 and 90) not null,
    longitude numeric check (longitude between -180 and 180) not null
);

create table graves(
    id serial primary key,
    plot_id integer references plots(id),
    is_occupied boolean default false,
    description text
);

create table funeralagencies(
    id serial primary key,
    name text unique not null,
    phone text not null check(phone ~ '^\+?[0-9]{5,12}$'),
    address text
);

create table services(
    id serial primary key,
    funeralagency_id integer references funeralagencies(id),
    name text not null,
    price numeric not null check(price >= 0)
);

create table deceased (
    id serial primary key,
    full_name varchar(40) not null,
    date_birthday date,
    date_dead date check (date_dead IS NULL OR date_birthday is null or date_dead >= date_birthday),
    cause_of_death text,
    grave_id integer unique references graves(id),
    funeralagency_id integer references funeralagencies(id),
    service_id integer REFERENCES services(id)
);

create table orders(
    id serial primary key,
    service_id integer references services(id),
    grave_id integer references graves(id),
    order_date date default current_date,
    status text not null
);

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

-- Триггер, что при добавлении погибшего мы добавляем строку в таблицу услуг с типом "захоронение"

CREATE OR REPLACE FUNCTION add_burial_order()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO orders (service_id, grave_id, order_date, status)
  VALUES (NEW.burial_service_id, NEW.grave_id, NEW.date_dead, 'выполнено');

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_add_burial_order
AFTER INSERT ON deceased
FOR EACH ROW
EXECUTE FUNCTION add_burial_order();
