/*
Лабораторная работа № 1
Выполнил студент группы ИБ -21
Лядков Алексей Сергеевич
*/

/* 
2.1.1 Создайте учебную базу данных Students. Для этого необходимо войти в
учетную запись postgres и подключиться к программе psql.

2.1.2 Выйдите из программы psql и заполните базу данных, используя файл
резервной копии.

su - postgres
2.1.1  create database students;
2.1.2 psql students < students_dump.sql
psql
\c students;

Проверка что все получилось: 
select * from students limit 5;
Все работает
*/

/*
2.1.3 Используя программу pgAdmin, ознакомьтесь со схемой данных, содержимым
таблиц БД. Определите число строк в каждой из таблиц.
*/

--\dt+

/*
2.1.4 Определите, какие таблицы в базе данных Students являются главными, а какие
для них подчиненными.

таблица professors ни скем не связана
остальные таблицы связаны между собой связями, например:
structural_units связано с employments связью 1:М
(Все таблицы связаны связью один ко многим, при этом вверху структуры
находится structural_units, к employments, students_group и field от них
от field к field_comprehensions, от students_group к students, а от него
к field_comprehensons и students_ids)
*/

/*
2.2.1. Подключитесь к созданной базе данных Students из-под командной строки.
Определите, какой размер на диске занимает таблица student?
*/

-- использую \dt+
-- students занимает 88 kB

/*
2.2.2. Создайте новую роль «Ваши инициалы junior». Выделите ей привилегии на
вход и установите пароль «654321». Подключитесь от её имени к базе данных
students и попробуйте удалить её с помощью запроса:
*/

-- через pgAdmin 4 интерактивно

CREATE ROLE LAS_junior WITH LOGIN PASSWORD '654321';
GRANT CONNECT ON DATABASE students TO LAS_junior;

-- не удалось удалить так как нет прав на удаление

/*
2.3.1. Выполните в соответствии с вариантом задание (см. таблицу ниже) на
изменение содержимого базы данных.]

Из-за конфликтов с одногруппниками, Роман Хлудов из группы ИВТ-
41 решил перевестись в группу ИВТ-42. Выполните данное изменение.
*/

-- или через pgAdmin через filter rows и интерактивное изменение
SELECT * FROM students WHERE first_name = 'Роман' AND last_name = 'Хлудов';

UPDATE students
SET students_group_number = 'ИВТ-42'
WHERE first_name = 'Роман' AND last_name = 'Хлудов';

SELECT * FROM students WHERE first_name = 'Роман' AND last_name = 'Хлудов';

/* 
2.3.2. После внесенных изменений, создайте новую резервную копию базы данных
Students.
*/

-- pg_dump -U postgres students > students_change_dump.sql
