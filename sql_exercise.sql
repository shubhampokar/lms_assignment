---> 1 	CREATE DATABASE SYNTAX 
CREATE DATABASE syntax;





---> 2 	CREATE SCHEMA SYNTAX
CREATE SCHEMA syntax;





---> 3 	"create table name test and test1 (with column id,  first_name, last_name, school, percentage, status (pass or fail),pin,
--->    created_date, updated_date) define constraints in it such as Primary Key, Foreign Key, Noit Null...
--->    apart from this take default value for some column such as cretaed_date"

CREATE TABLE test(
	id SERIAL PRIMARY KEY,
	first_name VARCHAR(15) NOT NULL,
	last_name VARCHAR(15) NOT NULL,
	school VARCHAR(75),
	percentage NUMERIC(5,2) DEFAULT 0,
	status VARCHAR(4) CHECK(status='pass' OR status='fail'),
	pin INT,
	created_date DATE DEFAULT CURRENT_DATE,
	updated_date DATE
);

CREATE TABLE test1(
	id SERIAL PRIMARY KEY,
	test1_id SERIAL NOT NULL,
	first_name VARCHAR(15) NOT NULL,
	last_name VARCHAR(15) NOT NULL,
	school VARCHAR(75),
	percentage NUMERIC(5,2) DEFAULT 0, 
	status VARCHAR(4) CHECK(status='pass' OR status='fail'), 
	pin INT,
	created_date DATE DEFAULT CURRENT_DATE, 
	updated_date DATE,
	CONSTRAINT fk_test FOREIGN KEY(test1_id) REFERENCES test(id)
);	





---> 4	Create film_cast table with film_id,title,first_name and last_name of the actor.. (create table from other table)
CREATE TABLE film_cast AS
SELECT 
	film_id, 
	title, 
	STRING_AGG (
		first_name || ' ' || last_name,
        ' --- '
       	ORDER BY first_name
    ) "cast" 
FROM film 
JOIN film_actor USING(film_id)
JOIN actor USING(actor_id)
GROUP BY film_id, title;

-- SELECT * FROM film_cast;





---> 5	drop table test1
DROP TABLE test1;





---> 6  what is temproray table ? what is the purpose of temp table ? create one temp table 

--Ans. 	Temporary table is a table that is not stored in the database permanently and exists only while the database session in which it was created is active.
--		Temporary table have many use cases. It helps to simplify our code, decreases execution time for our queries and many more.
CREATE TEMP TABLE dt_demo_sub_2 (a, b, c) 
AS 
SELECT uuid_dt, arr_dt, cust_dt
FROM datatype_demo
WHERE text_dt IS NULL;





---> 7  difference between delete and truncate ? 

--Ans. 	The DELETE statement removes rows one at a time and makes an entry in the transaction log for each rows. 
--		TRUNCATE statement removes the data by deallocating the data pages used to store the table data and records only the page deallocations in the transaction log. 
--		DELETE command is slower than TRUNCATE command.
--		DELETE can be used for removing particular record while TRUNCATE removes all records.





---> 8  rename test table to student table
ALTER TABLE test RENAME TO student;





---> 9  add column in test table named city 
ALTER TABLE student RENAME TO test;

ALTER TABLE test ADD COLUMN city VARCHAR(30);





---> 10  change data type of one of the column of test table
ALTER TABLE test ALTER COLUMN status TYPE CHAR(4);





---> 11  drop column pin from test table 
ALTER TABLE test DROP COLUMN pin;





---> 12  rename column city to location in test table
ALTER TABLE test RENAME COLUMN city TO location;





---> 13  Create a Role with read only rights on the database.
CREATE ROLE ReadOnlyUser
LOGIN PASSWORD '123456789';

GRANT CONNECT ON DATABASE local 
TO ReadOnlyUser;

GRANT USAGE ON SCHEMA syntax 
TO ReadOnlyUser;

GRANT SELECT ON ALL TABLES 
IN SCHEMA syntax 
TO ReadOnlyUser;

-- ALTER DEFAULT PRIVILEGES 
-- IN SCHEMA syntax 
-- GRANT SELECT ON TABLES 
-- TO ReadOnlyUser;





---> 14  Create a role with all the write permission on the database.
CREATE ROLE AllWriteUser
LOGIN PASSWORD '123456789';

GRANT INSERT, UPDATE, DELETE ON ALL TABLES 
IN SCHEMA syntax 
TO AllWriteUser;





---> 15  Create a database user who can only read the data from the database.
CREATE ROLE OnlyReadDataUser
LOGIN PASSWORD '123456789';

GRANT SELECT ON ALL TABLES 
IN SCHEMA syntax 
TO OnlyReadDataUser;

-- ALTER DEFAULT PRIVILEGES 
-- IN SCHEMA syntax 
-- GRANT SELECT ON TABLES 
-- TO OnlyReadDataUser;





---> 16  Create a database user who can read as well as write data into database.
CREATE ROLE OnlyReadUser
LOGIN PASSWORD '123456789';

GRANT SELECT ON ALL TABLES 
IN SCHEMA syntax 
TO OnlyReadUser;





---> 17  Create an admin role who is not superuser but can create database and  manage roles.
CREATE ROLE AdminOnlyUser WITH CREATEDB;

GRANT AdminOnlyUser TO CURRENT_ROLE WITH ADMIN OPTION;





---> 18  Create user whoes login credentials can last until 1st June 2023
CREATE ROLE LimitedTimeUser 
VALID UNTIL '2023-06-01';





---> 19  List all unique film’s name.
SELECT DISTINCT title FROM film;





---> 20  List top 100 customers details.
SELECT * FROM customer LIMIT 100;





---> 21  List top 10 inventory details starting from the 5th one.
SELECT * FROM inventory 
OFFSET 4 
FETCH FIRST 10 ROWS ONLY;





---> 22  find the customer's name who paid an amount between 1.99 and 5.99.
SELECT DISTINCT first_name || ' ' || last_name "name" 
FROM customer 
JOIN payment USING(customer_id)
WHERE amount BETWEEN 1.99 AND 5.99;





---> 23  List film's name which is staring from the A.
SELECT title
FROM film
WHERE title LIKE 'A%';





---> 24  List film's name which is end with "a"
SELECT title
FROM film
WHERE title LIKE '%a';





---> 25  List film's name which is start with "M" and ends with "a"
SELECT title
FROM film
WHERE title LIKE 'M%a';





---> 26  List all customer details which payment amount is greater than 40. (USING EXISTs)
SELECT * 
FROM customer c
WHERE EXISTS (
	SELECT 1
	FROM payment p
	WHERE amount>40 AND c.customer_id = p.customer_id
);





---> 27  List Staff details order by first_name.
SELECT * FROM staff ORDER BY first_name;





---> 28  List customer's payment details (customer_id,payment_id,first_name,last_name,payment_date)
SELECT customer_id, payment_id, first_name, last_name, payment_date 
FROM customer 
JOIN payment USING(customer_id);





---> 29  Display title and it's actor name.
SELECT title, "cast" FROM film_cast;





---> 30  List all actor name and find corresponding film id
SELECT 
	first_name, 
	last_name, 
	ARRAY_AGG(film_id) AS films
FROM film_actor
JOIN actor USING(actor_id)
GROUP BY first_name, last_name;





---> 31  List all addresses and find corresponding customer's name and phone.
SELECT address.*, first_name||' '||last_name AS customer_name
FROM address
LEFT JOIN customer USING(address_id)
ORDER BY address_id;





---> 32  Find Customer's payment (include null values if not matched from both tables)
--->	 (customer_id,payment_id,first_name,last_name,payment_date)
SELECT customer_id, payment_id, first_name, last_name, payment_date 
FROM customer 
FULL JOIN payment USING(customer_id);





---> 33  List customer's address_id. (Not include duplicate id )
SELECT DISTINCT address_id FROM customer;





---> 34  List customer's address_id. (Include duplicate id )
SELECT address_id FROM customer;





---> 35  List Individual Customers' Payment total.
SELECT customer_id, SUM(amount) "total_payment"
FROM customer 
JOIN payment USING(customer_id)
GROUP BY customer_id
ORDER BY customer_id;





---> 36  List Customer whose payment is greater than 80.
SELECT customer_id, SUM(amount) "total_payment"
FROM customer 
JOIN payment USING(customer_id)
GROUP BY customer_id
HAVING SUM(amount)>80
ORDER BY customer_id;





---> 37  Shop owners decided to give  5 extra days to keep  their dvds to all the rentees who rent the movie before
--->	 June 15th 2005 make according changes in db
UPDATE rental
SET return_date = return_date + INTERVAL '5 day'
WHERE rental_date < '2005-06-15';





---> 38  Remove the records of all the inactive customers from the Database
DELETE FROM customer WHERE activebool = FAlSE;





---> 39  count the number of special_features category wise.... total no.of deleted scenes, Trailers etc....
SELECT UNNEST(special_features), count(*)
FROM film
JOIN film_category USING(film_id)
GROUP BY UNNEST(special_features);

SELECT category_id,
       SUM((CASE WHEN features = 'Deleted Scenes' THEN 1 END)) AS "Deleted Scenes",
       SUM((CASE WHEN features = 'Trailers' THEN 1 END)) AS "Trailers",
       SUM((CASE WHEN features = 'Behind the Scenes' THEN 1 END)) AS "Behind the Scenes",
       SUM((CASE WHEN features = 'Commentaries' THEN 1 END)) AS "Commentaries"
FROM (
	SELECT film_id, title, UNNEST(special_features) "features" FROM film
) f
JOIN film_category USING(film_id)
GROUP BY category_id
ORDER BY category_id;





---> 40  count the numbers of records in film table
SELECT COUNT(*) FROM film;





---> 41  count the no.of special fetures which have Trailers alone, Trailers and Deleted Scened both etc....
--->	 solution for trailer only, trailer and deleted scenes both
-- WITH cte AS(
-- 	SELECT film_id, title, special_features
-- 	FROM film
-- 	WHERE 
-- 		special_features <@ ARRAY['Trailers', 'Deleted Scenes'] 
-- 		AND 
-- 		NOT special_features <@ ARRAY['Deleted Scenes']
-- )
-- SELECT special_features, COUNT(*) 
-- FROM cte 
-- GROUP BY special_features;

-- sol-1 for all possible condition

-- SELECT film_id, title,
--        (CASE WHEN features = 'Deleted Scenes' THEN 1 ELSE 0 END) AS "Deleted Scenes",
--        (CASE WHEN features = 'Trailers' THEN 1 ELSE 0 END) AS "Trailers",
--        (CASE WHEN features = 'Behind the Scenes' THEN 1 ELSE 0 END) AS "Behind the Scenes",
--        (CASE WHEN features = 'Commentaries' THEN 1 ELSE 0 END) AS "Commentaries"
-- FROM (
-- 	SELECT film_id, title, UNNEST(special_features) "features" FROM film
-- ) f
-- GROUP BY film_id, title
-- ORDER BY film_id;

-- SELECT film_id, title, special_features,
--        (CASE WHEN special_features @> ARRAY['Deleted Scenes'] THEN 1 ELSE 0 END) AS "Deleted Scenes",
--        (CASE WHEN special_features @> ARRAY['Trailers'] THEN 1 ELSE 0 END) AS "Trailers",
--        (CASE WHEN special_features @> ARRAY['Behind the Scenes'] THEN 1 ELSE 0 END) AS "Behind the Scenes",
--        (CASE WHEN special_features @> ARRAY['Commentaries'] THEN 1 ELSE 0 END) AS "Commentaries"
-- FROM film;

--sol in case order of items in special_features is not same
WITH cte AS(
	SELECT film_id, title, special_features,
	   (CASE WHEN special_features @> ARRAY['Deleted Scenes'] THEN 1 ELSE 0 END) AS "Deleted Scenes",
	   (CASE WHEN special_features @> ARRAY['Trailers'] THEN 1 ELSE 0 END) AS "Trailers",
	   (CASE WHEN special_features @> ARRAY['Behind the Scenes'] THEN 1 ELSE 0 END) AS "Behind the Scenes",
	   (CASE WHEN special_features @> ARRAY['Commentaries'] THEN 1 ELSE 0 END) AS "Commentaries"
	FROM film
)
SELECT "Deleted Scenes", "Trailers", "Behind the Scenes", "Commentaries", COUNT(*)
FROM cte
GROUP BY "Deleted Scenes", "Trailers", "Behind the Scenes", "Commentaries"
ORDER BY "Deleted Scenes", "Trailers", "Behind the Scenes", "Commentaries";


--sol 2
-- WITH cte AS(
-- 	SELECT film_id, title,
--        (CASE WHEN 'Deleted Scenes' = ANY(special_features) THEN 1 ELSE 0 END) AS "Deleted Scenes",
--        (CASE WHEN 'Trailers' = ANY(special_features) THEN 1 ELSE 0 END) AS "Trailers",
--        (CASE WHEN 'Behind the Scenes' = ANY(special_features) THEN 1 ELSE 0 END) AS "Behind the Scenes",
--        (CASE WHEN 'Commentaries' = ANY(special_features) THEN 1 ELSE 0 END) AS "Commentaries"
-- 	FROM film
-- )
-- SELECT "Deleted Scenes", "Trailers", "Behind the Scenes", "Commentaries", count(*)
-- FROM cte
-- GROUP BY CUBE("Deleted Scenes", "Trailers", "Behind the Scenes", "Commentaries")
-- HAVING 
-- 	"Deleted Scenes" IS NOT NULL 
-- 	AND 
-- 	"Trailers" IS NOT NULL 
-- 	AND 
-- 	"Behind the Scenes" IS NOT NULL 
-- 	AND 
-- 	"Commentaries" IS NOT NULL
-- ORDER BY "Deleted Scenes", "Trailers", "Behind the Scenes", "Commentaries";


-- sol in case all items in special_features remain in consistent order respectively
-- SELECT special_features, COUNT(*)
-- FROM film
-- GROUP BY special_features;





---> 42  use CASE expression with the SUM function to calculate the number of films in each rating:
SELECT
       SUM(CASE rating WHEN 'G' THEN 1 ELSE 0 END) "General Audiences",
       SUM(CASE rating WHEN 'PG' THEN 1 ELSE 0 END) "Parental Guidance Suggested",
       SUM(CASE rating WHEN 'PG-13' THEN 1 ELSE 0 END) "Parents Strongly Cautioned",
       SUM(CASE rating WHEN 'R' THEN 1 ELSE 0 END) "Restricted",
       SUM(CASE rating WHEN 'NC-17' THEN 1 ELSE 0 END) "Adults Only"
FROM film;





---> 43  Display the discount on each product, if there is no discount on product Return 0
SELECT id, product, COAlESCE(discount, 0) "discount"
FROM items;





---> 44  Return title and it's excerpt, if excerpt is empty or null display last 6 letters of respective body from posts table
SELECT title, COALESCE(NULLIF(excerpt, ''), RIGHT(body,6)) "excerpt" 
FROM posts;





---> 45  Can we know how many distinct users have rented each genre? if yes, name a category with highest and lowest rented number 
WITH cte AS(
	SELECT name, COUNT(DISTINCT customer_id) AS total 
	FROM rental
	JOIN inventory USING(inventory_id)
	JOIN film_category USING(film_id)
	JOIN category USING(category_id)
	GROUP BY category_id
)
(SELECT *, 'min' "info" FROM cte ORDER BY total LIMIT 1)
UNION
(SELECT *, 'max' "info" FROM cte ORDER BY total DESC LIMIT 1);





---> 46  "Return film_id,title,rental_date and rental_duration
--->	 according to rental_rate need to define rental_duration 
--->	 such as 
--->	 rental rate  = 0.99 --> rental_duration = 3
--->	 rental rate  = 2.99 --> rental_duration = 4
--->	 rental rate  = 4.99 --> rental_duration = 5
--->	 otherwise  6"
SELECT 
	film_id, 
	title, 
	rental_date,
	CASE 
		WHEN rental_rate=0.99 THEN 3
		WHEN rental_rate=2.99 THEN 4
		WHEN rental_rate=4.99 THEN 5
		ELSE 6
	END rental_duration
FROM rental
JOIN inventory USING(inventory_id)
JOIN film USING(film_id);





---> 47  Find customers and their email that have rented movies at priced $9.99.
SELECT customer_id, first_name||' '||last_name AS customer_name, email
FROM customer
JOIN payment USING(customer_id)
WHERE amount = 9.99;





---> 48  Find customers in store #1 that spent less than $2.99 on individual rentals, but have spent a total higher than $5.
-- data inconsistency
-- SELECT *
-- FROM customer c
-- JOIN rental USING (customer_id)
-- JOIN payment p USING (rental_id)
-- WHERE c.customer_id <> p.customer_id

-- select * from rental where rental_id=4591;
-- select * from payment where payment_id IN (19518, 25162, 29163, 31834);
-- select * from inventory where inventory_id = 2276;

-- SELECT distinct customer.customer_id
-- FROM public.customer 
-- JOIN rental USING (customer_id)
-- JOIN payment USING (rental_id)
-- WHERE store_id=1 AND payment.staff_id=1
-- ORDER BY customer.customer_id ASC;




-- (SELECT distinct customer.customer_id
-- FROM customer 
-- JOIN rental USING (customer_id)
-- JOIN payment USING (rental_id)
-- WHERE payment.staff_id=1)
-- EXCEPT
-- (SELECT distinct customer.customer_id
-- FROM customer 
-- JOIN rental USING (customer_id)
-- JOIN payment USING (rental_id)
-- WHERE payment.staff_id=1 AND amount>2.99
-- ORDER BY customer.customer_id)


-- staff id is different for rental as well as payment
-- considering payment staff id
-- SELECT *
-- FROM customer 
-- JOIN rental USING (customer_id)
-- JOIN payment USING (rental_id)
-- WHERE customer.customer_id IN (320, 215) AND payment.staff_id=1;

-- SELECT customer.customer_id, SUM(amount)
-- FROM customer 
-- JOIN rental USING (customer_id)
-- JOIN payment USING (rental_id)
-- WHERE customer.customer_id IN (320, 215) AND payment.staff_id=1
-- GROUP BY customer.customer_id;


-- SELECT customer_id, SUM(amount)
-- FROM payment
-- WHERE customer_id NOT IN (
-- 		SELECT distinct customer_id
-- 		FROM payment
-- 		WHERE staff_id=1 AND amount>2.99
-- 	) 
-- 	AND 
-- 	staff_id=1
-- GROUP BY customer_id
-- HAVING SUM(amount)>5;


SELECT customer_id, SUM(amount)
FROM (
	SELECT customer_id, amount, payment_id
	FROM payment
	WHERE staff_id = 1
) x
WHERE x.amount<2.99
GROUP BY customer_id
HAVING SUM(amount)>5
ORDER BY customer_id;





---> 49  Select the titles of the movies that have the highest replacement cost.
SELECT title, replacement_cost 
FROM film
WHERE replacement_cost = (
	SELECT MAX(replacement_cost) FROM film
);





---> 50  list the cutomer who have rented maximum time movie and also display the count of that... 
--->	 (we can add limit here too---> list top 5 customer who rented maximum time)
SELECT customer_id, COUNT(*) 
FROM rental 
JOIN customer USING (customer_id)
GROUP BY customer_id
ORDER BY customer_id
LIMIT 5;

SELECT DISTINCT(customer_id), COUNT(*)
FROM customer
JOIN rental USING(customer_id)
JOIN inventory USING(inventory_id)
JOIN film USING(film_id)
WHERE length = (SELECT MAX(length) FROM film)
GROUP BY customer_id
ORDER BY COUNT(*) DESC
LIMIT 5;





---> 51  Display the max salary for each department
SELECT dept_name, MAX(salary)
FROM employee
GROUP BY dept_name;





---> 52  "Display all the details of employee and add one extra column name max_salary (which shows max_salary dept wise) 
--->	 emp_id	 	emp_name   		dept_name		salary   max_salary
--->	 120	    ""Monica""		""Admin""		5000	 5000
--->	 101	    ""Mohan""		""Admin""		4000	 5000
--->	 116		""Satya""		""Finance""		6500	 6500
--->	 118		""Tejaswi""		""Finance""		5500	 6500
---> 	 like this way if emp is from admin dept then , max salary of admin dept is 5000, then in the max salary column 5000 
--->	 will be shown for dept admin
SELECT 
	*, 
	MAX(salary) OVER(PARTITION BY dept_name) AS max_dept_salary
FROM employee;





---> 53  "Assign a number to the all the employee department wise  
--->	 such as if admin dept have 8 emp then no. goes from 1 to 8, then if finance have 3 then it goes to 1 to 3
--->	 emp_id   	emp_name       dept_name   		salary  	no_of_emp_dept_wsie
--->	 120		""Monica""		""Admin""		5000		1
--->	 101		""Mohan""		""Admin""		4000		2
--->	 113		""Gautham""		""Admin""		2000		3
--->	 108		""Maryam""		""Admin""		4000		4
--->	 113		""Gautham""		""Admin""		2000		5
--->	 120		""Monica""		""Admin""		5000		6
---> 	 101		""Mohan""		""Admin""		4000		7
--->	 108		""Maryam""	    ""Admin""		4000		8
--->	 116		""Satya""	    ""Finance""		6500		1
--->	 118		""Tejaswi""		""Finance""		5500		2
---> 	 104		""Dorvin""		""Finance""		6500		3
--->	 106		""Rajesh""		""Finance""		5000		4
--->	 104		""Dorvin""		""Finance""		6500		5
--->	 118		""Tejaswi""		""Finance""		5500		6
SELECT 
	*, 
	ROW_NUMBER() OVER(PARTITION BY dept_name) AS "dept_wise_row_count"
FROM employee;





---> 54  Fetch the first 2 employees from each department to join the company. (assume that emp_id assign in the order of joining)
SELECT * 
FROM (
	SELECT 
		*, 
		ROW_NUMBER() OVER(PARTITION BY dept_name ORDER BY emp_id) AS "dept_wise_row_count"
	FROM employee
) x
WHERE dept_wise_row_count<3;





---> 55  Fetch the top 3 employees in each department earning the max salary.
--->	 sol for top 3 employee with different sal but max
SELECT * 
FROM (
	SELECT 
		*, 
		DENSE_RANK() OVER(PARTITION BY dept_name ORDER BY salary DESC) AS "dept_wise_row_count"
	FROM employee
) x
WHERE dept_wise_row_count<4;

-- sol for top 3 emp earning sal = max sal
-- SELECT * 
-- FROM (
-- 	SELECT 
-- 		*, 
-- 		ROW_NUMBER() OVER(PARTITION BY dept_name ORDER BY salary DESC) AS "dept_wise_row_count",
-- 		MAX(salary) OVER(PARTITION BY dept_name) AS max_dept_salary
-- 	FROM employee
-- ) x
-- WHERE dept_wise_row_count<4 AND salary=max_dept_salary;





---> 56  write a query to display if the salary of an employee is higher, lower or equal to the previous employee.
SELECT 
	emp_id,
	salary,
	LAG(salary) OVER(PARTITION BY dept_name ORDER BY emp_id) AS prev_emp_sal,
	CASE WHEN salary > LAG(salary) OVER(PARTITION BY dept_name ORDER BY emp_id) THEN 'Higher'
		 WHEN salary < LAG(salary) OVER(PARTITION BY dept_name ORDER BY emp_id) THEN 'Lower'
		 WHEN salary = LAG(salary) OVER(PARTITION BY dept_name ORDER BY emp_id) THEN 'Equal'
	end as sal_comp_wrt_prev_emp
FROM employee;





---> 57  Get all title names those are released on may DATE
SELECT DISTINCT title
FROM film
WHERE EXTRACT(MONTH FROM last_update) = 5;





---> 58  get all Payments Related Details from Previous week
SELECT * 
FROM payment 
WHERE payment_date BETWEEN NOW() - INTERVAL'7 days' AND NOW();





---> 59  Get all customer related Information from Previous Year
SELECT * 
FROM customer 
WHERE create_date BETWEEN NOW() - INTERVAL'1 year' AND NOW();





---> 60  What is the number of rentals per month for each store?
SELECT EXTRACT(MONTH FROM rental_date) AS rental_month, store_id, COUNT(*) "total_rental"
FROM rental
JOIN staff USING(staff_id)
GROUP BY rental_month, store_id
ORDER BY rental_month, store_id;





---> 61  Replace Title 'Date speed' to 'Data speed' whose Language 'English'
UPDATE film
SET title='Data Speed'
WHERE 
	title='Date Speed' 
	AND 
	language_id=(
		SELECT language_id FROM language WHERE name='English'
	);





---> 62  Remove Starting Character "A" from Description Of film
UPDATE film
SET description = REGEXP_REPLACE(description, '^A\s', '', 'i');





---> 63  if end Of string is 'Italian'then Remove word from Description of Title
UPDATE film
SET description = REGEXP_REPLACE(description, '\sItalian$', '', 'i');





---> 64  Who are the top 5 customers with email details per total sales
SELECT customer_id, email, SUM(amount)
FROM payment
JOIN customer USING(customer_id)
GROUP BY customer_id
ORDER BY SUM(amount) DESC
LIMIT 5;





---> 65  Display the movie titles of those movies offered in both stores at the same time.
SELECT title, film_id
FROM film
WHERE film_id IN (
	(
		SELECT film_id 
		FROM inventory
		WHERE store_id = 1
	)
	INTERSECT
	(	
		SELECT film_id 
		FROM inventory
		WHERE store_id = 2
	)
)
ORDER BY film_id;





---> 66  Display the movies offered for rent in store_id 1 and not offered in store_id 2.
(SELECT DISTINCT film_id
FROM inventory
WHERE store_id = 1)
EXCEPT
(SELECT DISTINCT film_id
FROM inventory
WHERE store_id = 2)
ORDER BY film_id;





---> 67  Show the number of movies each actor acted in
SELECT actor_id, count(*)
FROM film_actor
GROUP BY actor_id
ORDER BY actor_id;





---> 68  Find all customers with at least three payments whose amount is greater than 9 dollars
SELECT customer_id
FROM payment
JOIN customer USING(customer_id)
WHERE amount>9
GROUP BY customer_id
HAVING COUNT(*)>3
ORDER BY customer_id;





---> 69  find out the lastest payment date of each customer
SELECT customer_id, MAX(payment_date)
FROM payment
JOIN customer USING(customer_id)
GROUP BY customer_id
ORDER BY customer_id;





---> 70  Create a trigger that will delete a customer’s reservation record once the customer’s rents the DVD
CREATE FUNCTION del_cust_reservation()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS
$$
BEGIN 
	DELETE FROM reservation 
	WHERE NEW.customer_id = reservation.customer_id AND NEW.inventory_id = reservation.inventory_id;
	
	RETURN OLD;
END;
$$

CREATE TRIGGER delete_reservation
AFTER INSERT
ON rental
FOR EACH ROW
EXECUTE PROCEDURE del_cust_reservation();

SELECT * FROM reservation;
SELECT * FROM rental WHERE inventory_id IN (12, 13, 14, 15);
SELECT * FROM inventory WHERE inventory_id=13;
SELECT * FROM film WHERE film_id=3;
SELECT * FROM store WHERE store_id=2;

INSERT INTO rental(rental_date, inventory_id, customer_id, staff_id)
VALUES (NOW(), 13, 2, 2);





---> 71  Create a trigger that will help me keep track of all operations performed on the reservation table. I want to record 
--->	 whether an insert, delete or update occurred on the reservation table and store that log in reservation_audit table.
CREATE OR REPLACE FUNCTION modify_reservation()
RETURNS TRIGGER 
LANGUAGE PLPGSQL
AS
$$
BEGIN
	IF TG_OP = 'INSERT' THEN
		INSERT INTO reservation_audit VALUES('I', now(), NEW.customer_id, NEW.inventory_id, NEW.reserve_date);
			
	ELSIF TG_OP = 'DELETE' THEN	
		INSERT INTO reservation_audit VALUES('D', now(), OLD.customer_id, OLD.inventory_id, OLD.reserve_date);
			
	ELSIF TG_OP = 'UPDATE' THEN		
		INSERT INTO reservation_audit VALUES('U', now(), OLD.customer_id, OLD.inventory_id, OLD.reserve_date);
	END IF;

	RETURN COALESCE(NEW, OLD);
END;
$$

CREATE TRIGGER modify_reservation_trigger
AFTER INSERT OR DELETE OR UPDATE
ON public.reservation
FOR EACH ROW
EXECUTE PROCEDURE modify_reservation();

INSERT INTO reservation VALUES(5, 16, NOW());
UPDATE reservation SET inventory_id = 20 WHERE customer_id = 5;
DELETE FROM reservation WHERE customer_id = 5;

SELECT * FROM reservation_audit;





---> 72  Create trigger to prevent a customer for reserving more than 3 DVD’s.
CREATE FUNCTION check_reservation_limit()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS
$$
BEGIN
	IF(SELECT COUNT(customer_id) FROM reservation WHERE customer_id = NEW.customer_id) = 3 THEN 
		RAISE NOTICE 'DVD reservation limit reached, you cannot request any more reservation';
	ELSE
		RETURN NEW;
	END IF;
	
	RETURN NULL;
END;
$$

CREATE TRIGGER reservation_limit_trigger
BEFORE INSERT
ON reservation
FOR EACH ROW
EXECUTE PROCEDURE check_reservation_limit();

INSERT INTO reservation 
VALUES
	(6, 17, NOW()),
	(6, 18, NOW()),
	(6, 19, NOW()),
	(6, 20, NOW());

SELECT * FROM reservation;





---> 73  create a function which takes year as a argument and return the concatenated result of title which contain
--->	 'ful' in it and release year like this (title:release_year) --> use cursor in function
CREATE OR REPLACE FUNCTION get_movies(m_year INT)
   	RETURNS TEXT[] as $$
DECLARE 
	m_names TEXT[];
	rec RECORD;
	cur CURSOR(m_year INT) FOR
		SELECT title
		FROM film
		WHERE release_year = m_year AND title LIKE '%ful%';
BEGIN
   	OPEN cur(m_year);
	
   	LOOP
      	FETCH cur INTO rec;

		EXIT WHEN NOT FOUND;

        m_names := ARRAY_APPEND(m_names, rec.title||':'||m_year::TEXT);
   	END LOOP;
   
   	CLOSE cur;

   	RETURN m_names;
END; $$
LANGUAGE PLPGSQL;

SELECT UNNEST(get_movies(2006)) AS movie_title;





---> 74  Find top 10 shortest movies using for loop
DO
$$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN (
		SELECT title 
		FROM film 
		ORDER BY length, title
		LIMIT 10
	) LOOP
	
		RAISE NOTICE '%', rec.title;
    
	END LOOP;
END;
$$





---> 75  Write a function using for loop to derive value of 6th field in fibonacci series (fibonacci starts like this --> 1,1,...)
CREATE OR REPLACE FUNCTION nth_fibonacci(nth_num INT)
RETURNS INT
LANGUAGE PLPGSQL
AS
$$
DECLARE
	a INT := 1;
	b INT := 1;
	temp INT;
	i INT;
BEGIN 
   FOR i IN 2..nth_num
   LOOP
      temp:= a + b;
      a := b;
      b := temp;
   END LOOP;
   
   RETURN a;
END;
$$

SELECT nth_fibonacci(6);