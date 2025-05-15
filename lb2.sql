/*
Лабораторная работа № 2
Выполнил студент группы ИБ -21
Лядков Алексей Сергеевич
*/

/*
2.1.
Задание 1
Исследование типов данных
Предположим, что в магазине новый конструктор стоит 999 рублей и 99 копеек.
Студент С. решил приобрести для дальнейшей перепродажи 100000 таких товаров. Для
расчета общей суммы, которую необходимо заплатить был создан следующий скрипт на
языке PL/pgSQL. Более подробно о нём будет рассказано в одной из следующих
лабораторных работ. Обратите внимание, что значение суммы имеет тип real.

DO
$$
DECLARE
	summ real :=0.0;
BEGIN
	FOR i IN 1..100000 LOOP
		summ := summ + 999.99;
	END LOOP;
	RAISE NOTICE 'Summ = %;', summ;
--RAISE NOTICE 'Diff = %;', 99999000 - summ;
END
$$ language plpgsql;

Запустите скрипт. Раскомментируйте строку с вычислением разницы и определите,
сколько денег переплатил студент С? Объясните полученный результат. Измените тип
суммы на numeric и money. Какой результат был получен в обоих случаях?
*/

DO
$$
DECLARE
	summ real :=0.0;
BEGIN
	FOR i IN 1..100000 LOOP
		summ := summ + 999.99;
	END LOOP;
	RAISE NOTICE 'Summ = %;', summ;
    RAISE NOTICE 'Diff = %;', 99999000 - summ;
END
$$ language plpgsql;

/*
Вывод: 
ЗАМЕЧАНИЕ:  Summ = 9.999999e+07;
ЗАМЕЧАНИЕ:  Diff = -992;
*/

DO
$$
DECLARE
    summ numeric := 0.0;
BEGIN
    FOR i IN 1..100000 LOOP
        summ := summ + 999.99;
    END LOOP;
    RAISE NOTICE 'Summ = %', summ;
	RAISE NOTICE 'Diff = %;', 99999000 - summ;
END
$$ LANGUAGE plpgsql;

/*
Вывод:
ЗАМЕЧАНИЕ:  Summ = 99999000.00
ЗАМЕЧАНИЕ:  Diff = 0.00;
*/

DO
$$
DECLARE
    summ money := 0.0;
BEGIN
    FOR i IN 1..100000 LOOP
        summ := summ + 999.99::money;
    END LOOP;
    RAISE NOTICE 'Summ = %', summ;
	RAISE NOTICE 'Diff = %;', 99999000::money - summ;
END
$$ LANGUAGE plpgsql;

/*
Вывод:
ЗАМЕЧАНИЕ:  Summ = 99 999 000,00 ?
ЗАМЕЧАНИЕ:  Diff = 0,00 ?;
*/

/*
Написание запросов на языке SQL
Напишите SQL запросы к учебной базе данных в соответствии с вариантом. Запросы
брать из сборник запросов к учебной базе данных, расположенного ниже
*/

-- 2.2 
--1) Вывести самого старшего студента группы ИВТ-42

SELECT *, age(current_date, birthday) AS age
FROM students
WHERE students_group_number = 'ИВТ-42'
ORDER BY age DESC LIMIT 1;

-- 2) Вывести всех студентов, родившихся летом и осенью

SELECT *
FROM students
WHERE EXTRACT(MONTH FROM birthday) IN (6, 7, 8, 9, 10, 11);

-- 3) Выведите коды дисциплин, по которым зачёт получило больше 100 студентов

SELECT field, COUNT(student_id) AS number 
FROM field_comprehensions
WHERE mark >= 3
GROUP BY field
HAVING COUNT(student_id) > 100;

-- 4) Вывести количество отличных оценок у каждого студента, отсортировать по количеству. Оставить только тех, у кого пятерок больше 10.

SELECT s.last_name, 
       s.first_name, 
       (SELECT COUNT(*) 
        FROM field_comprehensions f 
        WHERE f.student_id = s.student_id AND f.mark = 5) AS kol_5
FROM students s
WHERE (SELECT COUNT(*) 
       FROM field_comprehensions f 
       WHERE f.student_id = s.student_id AND f.mark = 5) > 10
ORDER BY kol_5;

-- 5) Вывести студентов с почтой, начинающейся на латинскую букву A, отсортировать по имени студентов

SELECT * FROM students WHERE email LIKE 'A%' ORDER BY first_name;

-- 6) Выведите всех студентов, обучающихся на 2 курсе, исключая номер группы

SELECT student_id, last_name, first_name, patronymic, birthday, email FROM students
WHERE students_group_number LIKE '%-2%';

-- 7) Вывести общую сумму оклада по должностям, преподавателей чей стаж выше трех лет, округлив ее до сотых. Сумма превышающая 500т не выводится.

SELECT current_position, 
       SUM(salary) AS sum_salary 
FROM professors 
WHERE experience > 3 
GROUP BY current_position 
HAVING SUM(salary) < '500000'::money;

--8) Вывести всех студентов всех курсов второй группы ИТД, фамилии 
-- которых начинаются на букву из диапазона А-Н, убрать повторяющиеся фамилии,
--отсортировать по фамилии. Всем столбцам дать русские имена.


SELECT DISTINCT 
    student_id AS "уникальный индификатор", 
    last_name AS "фамилия",
	students_group_number as "группа"
FROM students
WHERE LEFT(last_name, 1) BETWEEN 'А' AND 'Н'
  AND students_group_number LIKE 'ИТД-_2'
ORDER BY last_name;

--2.3.
--Задание 3
--Самостоятельно разработайте 7 осмысленных запросов к базе данных, используя
--приведенные в данной лабораторной работе материалы.


--1) вывести 5 преподавателей с наибольшей зарплатой и опытом работы больше 10 лет

select * from professors
where experience > 10 
order by salary desc
limit 5;

--2) вывести сколько преподавателей с одной и той же зарплатой и с эту зарплату

select count(professor_id), salary from professors
group by salary;

--3) вывести средний возраст в каждой группе

SELECT 
    students_group_number, 
    ROUND(AVG(EXTRACT(YEAR FROM age(birthday))), 1) AS avg_age
FROM students
GROUP BY students_group_number
order by ROUND(AVG(EXTRACT(YEAR FROM age(birthday))), 1);

--4) вывести все группы в которых меньше 20 человек

select students_group_number, count(student_id) 
as "Количество людей в группе" from students
group by students_group_number having 
count(student_id) < 20
order by "Количество людей в группе";

--5) вывести общий возраст всех студентов

select sum(ROUND(EXTRACT(YEAR FROM age(birthday)), 1)) 
from students;

--6) вывести средний стаж преподавания

select round(avg(experience), 1)
from professors;

--7) вывести студентов у которых фамилия, имя и отчетсво начинается на одну букву и которым больше 20 лет

select last_name, first_name, patronymic, birthday
from students
where left(last_name, 1) = left(first_name, 1)
and left(first_name, 1) = left(patronymic, 1)
and extract(year from age(birthday)) > 20;

