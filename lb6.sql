/*
2.1.
Задание 1
Напишите скрипт на языке PL/pgSQL, вычисляющий среднюю оценку студента.
Аналогичный запрос напишите на языке SQL. Сравните время выполнения работы в
обоих случаях. Для расчета времени выполнения скрипта, запустите его в терминале psql,
перед этим запустив таймер с помощью команды \timing. Для того, чтобы отключить
таймер после окончания работы, выполните команду \timing off.
*/

select round(avg(mark), 2) as avg_mark from field_comprehensions
where student_id = 852957
group by student_id;


CREATE OR REPLACE FUNCTION get_average_mark(student_id_ INT)
RETURNS NUMERIC 
LANGUAGE plpgsql
AS 
$$
DECLARE
    avg_mark NUMERIC;
BEGIN
    SELECT round(AVG(mark),2)
    INTO avg_mark
    FROM field_comprehensions
    WHERE student_id = student_id_;

    RETURN avg_mark;
END;
$$;



\timing
SELECT get_average_mark(852957);
\timing off

--Время: 16,827 мс

\timing
select round(avg(mark), 2) as avg_mark from field_comprehensions
where student_id = 852957
group by student_id;
\timing off
--Время: 1,201 мс


/*
2.2.
Задание 2
Напишите SQL запросы к учебной базе данных в соответствии с вариантом.
Вариант к практической части выбирается по формуле: V = (N % 10) +1, где N – номер в
списке группы, % - остаток от деления.
*/

-- Вар 4: 4, 14, 24, 34, 44, 54, 64

/*
Напишите скрипт, который возвращает фамилию, имя студентов со счастливым
студенческим билетом (сумма первых трех цифр номера билета совпадает с
суммой последних трех)
*/

create type lucky_type as (
	last_name varchar(30),
	first_name varchar(30),
	student_id integer
);

create or replace function luсky()
returns setof lucky_type
language sql
as 
$$
	select last_name, first_name, student_id from students
	 where 
	 (
        -- сумма первых трёх цифр
        (SUBSTRING(student_id::TEXT FROM 1 FOR 1))::INT +
        (SUBSTRING(student_id::TEXT FROM 2 FOR 1))::INT +
        (SUBSTRING(student_id::TEXT FROM 3 FOR 1))::INT
    ) =
    (
        -- сумма последних трёх цифр
        (SUBSTRING(student_id::TEXT FROM LENGTH(student_id::TEXT) - 2 FOR 1))::INT +
        (SUBSTRING(student_id::TEXT FROM LENGTH(student_id::TEXT) - 1 FOR 1))::INT +
        (SUBSTRING(student_id::TEXT FROM LENGTH(student_id::TEXT) FOR 1))::INT
    );
$$;

select * from luсky();
-------------------------------------------------------------------------------------------------
do
$$
declare
    r record;
    first_sum int;
    last_sum int;
begin
    raise notice 'фамилия | имя | student_id';

    for r in 
        select last_name, first_name, student_id from students
    loop
        first_sum := 
            (substring(r.student_id::text from 1 for 1))::int +
            (substring(r.student_id::text from 2 for 1))::int +
            (substring(r.student_id::text from 3 for 1))::int;

        last_sum := 
            (substring(r.student_id::text from length(r.student_id::text) - 2 for 1))::int +
            (substring(r.student_id::text from length(r.student_id::text) - 1 for 1))::int +
            (substring(r.student_id::text from length(r.student_id::text) for 1))::int;

        if first_sum = last_sum then
            raise notice '% | % | %', r.last_name, r.first_name, r.student_id;
        end if;
    end loop;
end
$$;


/*
14 Напишите скрипт, отбирающий случайным образом 10 студентов из списка
студентов 3-го курса, имеющих больше 10 двоек для участия в субботнике.
Выведите фамилию имя и количество двоек у студента.
*/

create type lagging_students_type as (
	last_name varchar(30),
	count_two integer
);

create or replace function lagging_students()
returns setof lagging_students_type
language sql
as
$$
	select s.last_name, count(*) as count_two from students s
	join field_comprehensions f
	on f.student_id = s.student_id
	where s.students_group_number like '%-3_' and f.mark = 2
	group by s.student_id 
	having count(*) > 10
	order by random()
	limit 10;
$$;

select * from lagging_students();
---------------------------------------------------------------------------------
do
$$
declare
    r record;
begin
    raise notice 'фамилия | кол-во двоек';

    for r in
        select s.last_name, count(*) as count_two
        from students s
        join field_comprehensions f on f.student_id = s.student_id
        where s.students_group_number like '%-3_'
          and f.mark = 2
        group by s.student_id, s.last_name
        having count(*) > 10
        order by random()
        limit 10
    loop
        raise notice '% | %', r.last_name, r.count_two;
    end loop;
end
$$;

/*
24 Создайте процедуру, изменяющую преподавателя у данной дисциплины. Входные
параметры – id нового преподавателя, название дисциплины).
*/

select * from fields;

--"f81d63d6-ccd0-4cf0-a13a-340c44b852af"	"Иностранный язык"	7	870001	3	1

create procedure update_teacher(new_professor_id integer, field_name_ varchar(100))
language sql
as 
$$
	update fields set professor_id = new_professor_id
	where field_name = field_name_
$$;

call update_teacher(823012, 'Иностранный язык');

select * from fields
where field_name = 'Иностранный язык';

/*
"f81d63d6-ccd0-4cf0-a13a-340c44b852af"	"Иностранный язык"	7	823012	3	1
"f3428708-dd90-42cd-a568-f344cefa3ffd"	"Иностранный язык"	7	823012	3	1
"e410103b-9a1d-49c1-82cd-368e711fa6d8"	"Иностранный язык"	7	823012	3	1
*/

/*
34 Создайте функцию, рассчитывающую среднюю зарплату преподавателей в
определенном структурном подразделении.
*/

create or replace function avg_salary(structural_unit_id_ integer)
returns numeric
language sql
as
$$
	select round(avg(p.salary::numeric), -1) as avg_salary from professors p
	join employments e 
	on p.professor_id = e.professor_id
	where e.structural_unit_id = structural_unit_id_
	group by e.structural_unit_id
$$;

select avg_salary(2);

/*
44 Создайте функцию, выводящую всех однофамильцев определенного студента.
Выведите девушек и юношей с аналогичной фамилией, а также их группу.
*/

create type namesakes_type as (
	last_name varchar(30),
	first_name varchar(30),
	group_number varchar(7)
);

create or replace function namesakes_type(last_name_ varchar(30))
returns setof namesakes_type
language sql
as
$$
	select last_name, first_name, students_group_number
	from students
	where last_name = last_name_;
$$;

select * from namesakes_type('Васин');

-- 54 Создайте триггер, который запрещает изменение в структурных подразделениях

create or replace function block_department_changes()
returns trigger
language plpgsql
as
$$
begin
    raise exception 'Изменения в структурных подразделениях запрещены.';
end;
$$;

create trigger prevent_department_modifications
before update or delete on structural_units
for each row
execute function block_department_changes();

update structural_units set structural_unit_id = 1111
where structural_unit_id = 1;

/*
ERROR:  Изменения в структурных подразделениях запрещены.
CONTEXT:  функция PL/pgSQL block_department_changes(), строка 3, оператор RAISE 

ОШИБКА:  Изменения в структурных подразделениях запрещены.
SQL state: P0001
*/

-- 64 Создайте триггер, сохраняющий информацию о изменении зарплаты
-- преподавателей и дату изменения.

create table if not exists log_update_salary (
    professor_id integer,
    old_salary money,
    new_salary money,
    data_update date
);

create or replace function log_update_salary_function()
returns trigger
language plpgsql
as
$$
begin
    insert into log_update_salary
    values (old.professor_id, old.salary, new.salary, current_date); 
    return new; 
end;
$$;

create trigger log_update_salary_trigger
before update on professors  
for each row
when (old.salary <> new.salary)  
execute function log_update_salary_function();

update professors 
set salary = '101'
where professor_id = 801001;

select * 
from log_update_salary;

/*
2.3.
Задание 3
Для добавленной в 4-й лабораторной работе таблицы создайте любой триггер.
*/

create table if not exists log_change_in_military_tables (
    name_table varchar(50),
    name_role varchar(30),
    data_update date,
    name_operation varchar(30)
);

create or replace function log_change_in_military_tables_function()
returns trigger
language plpgsql
as
$$
begin
    insert into log_change_in_military_tables (
        name_table, name_role, data_update, name_operation
    )
    values (
        tg_table_name,        
        session_user,          
        current_date,         
        tg_op                 
    );
    return new;
end;
$$;

create trigger log_change_in_military_tables_trigger
before insert or update or delete on military_mark
for each row
execute function log_change_in_military_tables_function();

create trigger log_change_in_military_tables_trigger
before insert or update or delete on military_courses
for each row
execute function log_change_in_military_tables_function();

create trigger log_change_in_military_tables_trigger
before insert or update or delete on military_enrollment
for each row
execute function log_change_in_military_tables_function();

create trigger log_change_in_military_tables_trigger
before insert or update or delete on military_teachers
for each row
execute function log_change_in_military_tables_function();

update military_mark 
set mark = 3
where id = 1;

update military_teachers
set rank = 'Капитан'
where id = 1;

select * 
from log_change_in_military_tables;
