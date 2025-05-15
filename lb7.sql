/*
2.1.1.
Исследование производительности системы
Создайте таблицу, содержащую значения посещаемости студентом института.
Таблица содержит номер студенческого билета, время его входа, выхода и
сгенерированное случайное кодовое число при выходе из вуза.
*/

CREATE TABLE attendance (
    attendance_id SERIAL PRIMARY KEY,
    generated_code VARCHAR(64),
    person_id integer,
    enter_time timestamp,
    exit_time timestamp,
    FOREIGN KEY (person_id) REFERENCES student_ids (student_id)
);

-- С помощью следующего скрипта заполните таблицу данными.

DO $$
DECLARE
    enter_time timestamp(0);
    exit_time timestamp(0);
    person_id integer;
    enter_id VARCHAR(64);
BEGIN
    FOR i IN 1..1000000 LOOP
        enter_time := to_timestamp(random() *
            (
                extract(epoch from DATE '2023-12-31') -
                extract(epoch from DATE '2023-01-01')
            )
            + extract(epoch from DATE '2023-01-01')
        );

        exit_time := enter_time + (floor(random() * 36000 + 1) * INTERVAL '1 second');

        SELECT student_id INTO person_id
        FROM students
        ORDER BY random()
        LIMIT 1;

        enter_id := md5(random()::text);

        INSERT INTO attendance(generated_code, person_id, enter_time, exit_time)
        VALUES (enter_id, person_id, enter_time, exit_time);
    END LOOP;
END
$$ LANGUAGE plpgsql;

-- Я добавил функцию, для добавления одной записи в attendance

CREATE TYPE note_attendance AS (
    enter_time timestamp(0),
    exit_time timestamp(0),
    person_id integer,
    enter_id VARCHAR(64)
);

CREATE OR REPLACE FUNCTION add_note_in_attendance()
RETURNS SETOF note_attendance
LANGUAGE plpgsql
AS
$$
DECLARE
    rec note_attendance;
BEGIN
    rec.enter_time := to_timestamp(random() *
        (
            extract(epoch from DATE '2023-12-31') -
            extract(epoch from DATE '2023-01-01')
        )
        + extract(epoch from DATE '2023-01-01')
    );

    rec.exit_time := rec.enter_time + (floor(random() * 36000 + 1) * INTERVAL '1 second');

    SELECT student_id INTO rec.person_id
    FROM students
    ORDER BY random()
    LIMIT 1;

    rec.enter_id := md5(random()::text);

    RETURN NEXT rec;
END
$$;

/*
Добавьте в таблицу attendance одно значение, измерив время данной операции.
Далее измерьте время выполнения запроса, выводящего содержимого таблицы в
отсортированном виде по столбцу generated_code.
Добавьте индекс на столбец generated_code. Повторите предыдущие две операции.
Сравните полученное время. Во сколько раз оно изменилось? Результаты вычисления
занесите в таблицу.
*/


EXPLAIN ANALYZE
INSERT INTO attendance(generated_code, person_id, enter_time, exit_time)
SELECT enter_id, person_id, enter_time, exit_time
FROM add_note_in_attendance();

/*
"Insert on attendance  (cost=0.25..15.25 rows=0 width=0) (actual time=0.841..0.841 rows=0 loops=1)"
"  ->  Function Scan on add_note_in_attendance  (cost=0.25..15.25 rows=1000 width=170) (actual time=0.815..0.816 rows=1 loops=1)"
"Planning Time: 0.060 ms"
"Trigger for constraint attendance_person_id_fkey: time=0.051 calls=1"
"Execution Time: 1.819 ms"
*/

-- Я повторил несколько раз, значения реального времени колеблятся в районе одной секунды

/*
"Insert on attendance  (cost=0.25..15.25 rows=0 width=0) (actual time=0.957..0.958 rows=0 loops=1)"
"  ->  Function Scan on add_note_in_attendance  (cost=0.25..15.25 rows=1000 width=170) (actual time=0.849..0.850 rows=1 loops=1)"
"Planning Time: 0.167 ms"
"Trigger for constraint attendance_person_id_fkey: time=0.121 calls=1"
"Execution Time: 1.138 ms"
*/

EXPLAIN ANALYZE
SELECT * FROM attendance 
ORDER BY generated_code;

/*
"Gather Merge  (cost=71089.50..168318.59 rows=833334 width=57) (actual time=4288.012..7914.731 rows=1000009 loops=1)"
"  Workers Planned: 2"
"  Workers Launched: 2"
"  ->  Sort  (cost=70089.48..71131.15 rows=416667 width=57) (actual time=4108.013..5468.653 rows=333336 loops=3)"
"        Sort Key: generated_code"
"        Sort Method: external merge  Disk: 25264kB"
"        Worker 0:  Sort Method: external merge  Disk: 23880kB"
"        Worker 1:  Sort Method: external merge  Disk: 23312kB"
"        ->  Parallel Seq Scan on attendance  (cost=0.00..15530.67 rows=416667 width=57) (actual time=0.018..43.378 rows=333336 loops=3)"
"Planning Time: 4.046 ms"
"Execution Time: 8015.141 ms"
*/

CREATE INDEX generated_code_index ON attendance (generated_code);

EXPLAIN ANALYZE
INSERT INTO attendance(generated_code, person_id, enter_time, exit_time)
SELECT enter_id, person_id, enter_time, exit_time
FROM add_note_in_attendance();

/*
"Insert on attendance  (cost=0.25..15.25 rows=0 width=0) (actual time=0.778..0.779 rows=0 loops=1)"
"  ->  Function Scan on add_note_in_attendance  (cost=0.25..15.25 rows=1000 width=170) (actual time=0.543..0.544 rows=1 loops=1)"
"Planning Time: 0.079 ms"
"Trigger for constraint attendance_person_id_fkey: time=0.122 calls=1"
"Execution Time: 0.954 ms"
*/

EXPLAIN ANALYZE
SELECT * FROM attendance 
ORDER BY generated_code;

/*
"Index Scan using generated_code_index on attendance  (cost=0.42..89293.02 rows=1000009 width=57) (actual time=0.217..1568.958 rows=1000010 loops=1)"
"Planning Time: 0.132 ms"
"Execution Time: 1621.894 ms"
*/

/*

______________________________________________________________________________________
|       | Время до индексирования T_b | Время после индексирования T_a |   T_a / T_b |
|_______|_____________________________|________________________________|_____________|
|select |          8015 ms            |             1621 ms            |             |  
|_______|_____________________________|________________________________|_____________|
|insert |          1.138 ms           |            0.954 ms            |             |
|_______|_____________________________|________________________________|_____________|

*/

/*
2.1.2.
Индексы и селективность
Выполните запрос, выводящий все строки таблицы attendance, измерьте время его
выполнения. Добавьте условие, выбрав только все записи, связанные с одним конкретным
студентом. Аналогично измерьте время выполнения. Создайте индекс на атрибут
person_id и повторите эксперименты. Сравните время выполнения операций до создания
индекса и после. Объясните полученный результат.
*/

EXPLAIN ANALYZE
SELECT * FROM attendance;

/*
"Seq Scan on attendance  (cost=0.00..21364.09 rows=1000009 width=57) (actual time=0.018..100.578 rows=1000023 loops=1)"
"Planning Time: 0.124 ms"
"Execution Time: 147.173 ms"
*/

EXPLAIN ANALYZE
SELECT * FROM attendance
WHERE person_id = 832921;

/*
"Gather  (cost=1000.00..17778.38 rows=2060 width=57) (actual time=0.596..182.888 rows=2121 loops=1)"
"  Workers Planned: 2"
"  Workers Launched: 2"
"  ->  Parallel Seq Scan on attendance  (cost=0.00..16572.38 rows=858 width=57) (actual time=0.045..65.366 rows=707 loops=3)"
"        Filter: (person_id = 832921)"
"        Rows Removed by Filter: 332634"
"Planning Time: 0.160 ms"
"Execution Time: 183.235 ms"
*/

CREATE INDEX person_id_index ON attendance (person_id);

EXPLAIN ANALYZE
SELECT * FROM attendance;

/*
"Seq Scan on attendance  (cost=0.00..21364.23 rows=1000023 width=57) (actual time=0.049..142.427 rows=1000023 loops=1)"
"Planning Time: 3.639 ms"
"Execution Time: 207.116 ms"
*/

EXPLAIN ANALYZE
SELECT * FROM attendance
WHERE person_id = 832921;

/*
"Bitmap Heap Scan on attendance  (cost=24.39..5295.65 rows=2060 width=57) (actual time=2.721..6.496 rows=2121 loops=1)"
"  Recheck Cond: (person_id = 832921)"
"  Heap Blocks: exact=1919"
"  ->  Bitmap Index Scan on person_id_index  (cost=0.00..23.88 rows=2060 width=0) (actual time=1.801..1.802 rows=2121 loops=1)"
"        Index Cond: (person_id = 832921)"
"Planning Time: 0.217 ms"
"Execution Time: 6.916 ms"
*/

/*

______________________________________________________________________________________________
|               | Время до индексирования T_b | Время после индексирования T_a |   T_a / T_b |
|_______________|_____________________________|________________________________|_____________|
|select         |          147  ms            |             207  ms            |             |  
|_______________|_____________________________|________________________________|_____________|
|select + where |          183 ms             |             6.9 ms             |             |
|_______________|_____________________________|________________________________|_____________|

*/


/*
2.1.3.
Анализ плана выполнения запроса
Составьте запрос к таблице attendance, выводящий все строки в отсортированном
порядке, в которых столбец generated_code заканчивается символом ‘a’. Проанализируйте
полученный запрос и объясните результат. Используется ли в данном случае индекс?
*/

explain analyze 
select * from attendance 
where right(generated_code, 1) = 'a'
order by generated_code;

/*
"Gather Merge  (cost=18728.99..19215.05 rows=4166 width=57) (actual time=526.493..630.950 rows=62479 loops=1)"
"  Workers Planned: 2"
"  Workers Launched: 2"
"  ->  Sort  (cost=17728.96..17734.17 rows=2083 width=57) (actual time=389.455..394.150 rows=20826 loops=3)"
"        Sort Key: generated_code"
"        Sort Method: quicksort  Memory: 3740kB"
"        Worker 0:  Sort Method: quicksort  Memory: 2027kB"
"        Worker 1:  Sort Method: quicksort  Memory: 2500kB"
"        ->  Parallel Seq Scan on attendance  (cost=0.00..17614.14 rows=2083 width=57) (actual time=0.020..183.842 rows=20826 loops=3)"
"              Filter: (""right""((generated_code)::text, 1) = 'a'::text)"
"              Rows Removed by Filter: 312515"
"Planning Time: 0.139 ms"
"Execution Time: 635.690 ms"
*/

-- я считаю, что здесь индекс не нужен, так как индексы создаются для частых запросов, этот запрос таковым не является





/*
2.2.
Задание 2
Предположим, что студент группы ИВТ-42 Полиграф Шариков во время зимней
сессии пересдал экзамен по дисциплине «Операционные системы» на оценку 5 и пересдал
экзамен по дисциплине «Базы данных» на 5 Одновременно с проставлением баллов за его
успехами следила методист кафедры. Для работы с несколькими транзакциями запустите
два командных окна (запросника). В первом вводите команды за преподавателя,
проставляющего оценки, а во втором за методиста, просматривающего результаты.
2.2.1.
Работа с транзакциями
В рамках транзакции измените значение оценки студента по Операционным
системам и проверьте значение в первом и втором окне. Зафиксируйте изменения и вновь
проверьте значения. Аналогично внесите новую оценку по Базам данных и проверьте
изменения.
*/

select s.first_name, s.last_name, s.students_group_number,
f.mark, fl.field_name from students s join public.field_comprehensions f
on s.student_id = f.student_id join fields fl on
fl.field_id = f.field
where s.first_name = 'Полиграф' and s.last_name = 'Шариков' and
(fl.field_name = 'Базы данных' or fl.field_name = 'Операционные системы');

/*
"Полиграф"	"Шариков"	"ИВТ-42"	2	"Операционные системы"
"Полиграф"	"Шариков"	"ИВТ-42"	2	"Базы данных"
*/

update field_comprehensions set mark = 5
where student_id = (select student_id from students 
					where first_name = 'Полиграф' and last_name = 'Шариков' and students_group_number = 'ИВТ-42')
	  and field in (select fl.field_id from fields fl
	  				where fl.field_name = 'Базы данных' or fl.field_name = 'Операционные системы');

/*
В том же окне
"Полиграф"	"Шариков"	"ИВТ-42"	5	"Операционные системы"
"Полиграф"	"Шариков"	"ИВТ-42"	5	"Базы данных"
*/

-- В другом окне аналогично


-- Это потому что я не использовал транзакцию. Вот исправленная версия:

BEGIN;

update field_comprehensions set mark = 5
where student_id = (select student_id from students 
					where first_name = 'Полиграф' and last_name = 'Шариков' and students_group_number = 'ИВТ-42')
	  and field in (select fl.field_id from fields fl
	  				where fl.field_name = 'Базы данных' or fl.field_name = 'Операционные системы');

--commit;

select s.first_name, s.last_name, s.students_group_number,
f.mark, fl.field_name from students s join public.field_comprehensions f
on s.student_id = f.student_id join fields fl on
fl.field_id = f.field
where s.first_name = 'Полиграф' and s.last_name = 'Шариков' and
(fl.field_name = 'Базы данных' or fl.field_name = 'Операционные системы');

--Без commit в нашем окне происходят изменения, а в другом нет, с коммитом изменения и там и там.


/*
2.2.2.
Отмена изменений транзакций
Удалите добавленное значение и верните исправленную оценку в прежнее
состояние. Повторите аналогичные действия, только по окончании внесения изменений
преподавателем откатите их с помощью команды ROLLBACK. Какое значение увидела
методист?
*/


BEGIN;

update field_comprehensions set mark = 2
where student_id = (select student_id from students 
					where first_name = 'Полиграф' and last_name = 'Шариков' and students_group_number = 'ИВТ-42')
	  and field in (select fl.field_id from fields fl
	  				where fl.field_name = 'Базы данных' or fl.field_name = 'Операционные системы');

rollback;

select s.first_name, s.last_name, s.students_group_number,
f.mark, fl.field_name from students s join public.field_comprehensions f
on s.student_id = f.student_id join fields fl on
fl.field_id = f.field
where s.first_name = 'Полиграф' and s.last_name = 'Шариков' and
(fl.field_name = 'Базы данных' or fl.field_name = 'Операционные системы');


/*
2.2.3.
Моделирование аномалий при выполнении транзакций
Повторите эксперименты в п. 2.2.1, используя различные уровни изоляции.

Внесите в таблицу в какой момент были получены ошибочные значения из-за
аномалий.
*/

/*
_________________________________________________________________________________
|Уровень изоляции|           До фиксации       |          После фиксации        |
|________________|_____________________________|________________________________|
|Read uncommited |               -             |                -               |             
|________________|_____________________________|________________________________|
|Read committed  |  транзакция уже выполняется |   текущая транзакция прервана  | 
|________________|_____________________________|________________________________|
|Repeatable read |  текущая транзакция прервана|  текущая транзакция прервана   |
|________________|_____________________________|________________________________|
|Serializable    | текущая транзакция прервана |  текущая транзакция прервана   |    
|________________|_____________________________|________________________________|


*/


/*
2.3.
Задание 3
Проанализируйте учебную базу данных и проиндексируйте одно из полей любой
таблицы. Объясните свой выбор.
*/

CREATE INDEX student_id_inx ON students (student_id);

-- Я проиндексировал это поле, потому что оно является одно из основных связующих полей в базе данных между таблицами
-- К тому же это ведь база данных студентов, и логичено, что в ней будут наиболее часто происходить операции именно
-- Над студентами, а не преподавателями или предметами, поэтому часто будут использоваться сортировки связанные с student_id