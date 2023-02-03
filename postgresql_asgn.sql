------------****-----------> 1. Quering Data <-----------****-----------
SELECT examinationroom, count(DISTINCT patient) "total_patient"
FROM appointment
GROUP BY examinationroom
ORDER BY examinationroom;





------------****-----------> 2. Filtering data <-----------****-----------
SELECT player_id, player_name, jersey_no, age
FROM player_mast
WHERE age BETWEEN 24 AND 27
LIMIT 5
OFFSET 4;


SELECT player_id, player_name, jersey_no, age
FROM player_mast
WHERE age IN (24, 25, 26, 27)
OFFSET 4
FETCH FIRST 5 ROWS ONLY;





------------****-----------> 3. Joining multiple tables <-----------****-----------
SELECT physician "physician_id", name, department, primaryaffiliation, certificationdate
FROM affiliated_with a
NATURAL JOIN trained_in b
JOIN physician p 
	ON p.employeeid = a.physician;


INSERT INTO nurse
VALUES	(104, 'Mary Ann', 'Nurse', true, 444444440),
		(105, 'Agnes Bernatitus', 'Nurse', false, 555555550);
            
            
SELECT employeeid AS "nurse_id", name, blockfloor, blockcode, oncallstart, oncallend
FROM nurse n
LEFT JOIN on_call o
ON n.employeeid = o.nurse;


SELECT * 
FROM prescribes p 
RIGHT JOIN medication m ON p.medication = m.code;


SELECT * 
FROM prescribes p 
FULL JOIN medication m ON p.medication = m.code;


SELECT e.first_name || ' ' || e.last_name employee_name, m.first_name || ' ' || m.last_name manager_name
FROM employees e
INNER JOIN employees m ON m.employee_id = e.manager_id;


SELECT * 
FROM genres 
CROSS JOIN movie_genres;





------------****-----------> 4. Grouping data <-----------****-----------
SELECT gen_id, COUNT(mov_id) "total_movie"
FROM movie_genres
GROUP BY gen_id
HAVING COUNT(DISTINCT mov_id) > 2;





------------****-----------> 5. Set Operations <-----------****-----------
CREATE TABLE IF NOT EXISTS generic_medication
(
    code integer PRIMARY KEY,
    name text NOT NULL,
    brand text NOT NULL,
    description text NOT NULL
);


INSERT INTO generic_medication
VALUES 	(101, 'Alprazolam', 'ABC', 'N/A'),
		(102, 'Altretamine', 'ABC', 'N/A'),
		(103, 'Phenytoin', 'ABC', 'N/A');
		

SELECT * FROM medication
UNION ALL
SELECT * FROM generic_medication;


SELECT * FROM medication
INTERSECT
SELECT * FROM generic_medication;

SELECT * FROM medication
EXCEPT 
SELECT * FROM generic_medication
ORDER BY code;





------------****-----------> 6. Subquery <-----------****-----------
SELECT * FROM genres
WHERE gen_id = ANY	(
		SELECT gen_id FROM movie_genres
		GROUP BY gen_id HAVING COUNT(DISTINCT mov_id) > 2
	);
	
	
SELECT * FROM genres
WHERE gen_id > ALL(
		SELECT gen_id FROM movie_genres
		GROUP BY gen_id HAVING COUNT(DISTINCT mov_id) > 2
	);
	

SELECT gen_title FROM genres g
WHERE EXISTS (
		SELECT gen_id FROM movie_genres m
		GROUP BY gen_id HAVING COUNT(DISTINCT mov_id) > 2 AND g.gen_id = m.gen_id
	);


SELECT * FROM genres g
WHERE NOT EXISTS (
		SELECT gen_id FROM movie_genres m
		GROUP BY gen_id HAVING COUNT(DISTINCT mov_id) > 2 AND g.gen_id = m.gen_id
	);





------------****-----------> 7. Common Table Expressions <-----------****-----------
WITH RECURSIVE mng_hierarchy AS (
	SELECT * FROM employees WHERE employee_id = 106
	UNION
	SELECT e.* FROM mng_hierarchy h JOIN employees e ON h.manager_id = e.employee_id
) 
SELECT * FROM mng_hierarchy;





------------****-----------> 8. Modifying Data <-----------****-----------
INSERT INTO nurse
VALUES	(104, 'Mary Ann', 'Nurse', true, 444444440),
		(105, 'Agnes Bernatitus', 'Nurse', false, 555555550);
		
SELECT * FROM nurse;
		
		
UPDATE nurse SET name = 'Agness Bernatitus' WHERE employeeid = 105
RETURNING *;


SELECT * FROM appointment;

SELECT * FROM nurse;

UPDATE appointment 
SET prepnurse = x.employeeid
FROM (SELECT employeeid FROM nurse WHERE position = 'Intern Nurse') x
WHERE prepnurse IS NULL; 

	
DELETE FROM nurse WHERE employeeid IN (104,105);


INSERT INTO nurse
VALUES(104, 'Lucy Fullbuster', 'Nurse', true, 444444440)
ON CONFLICT ON CONSTRAINT nurse_pkey 
DO NOTHING;


INSERT INTO nurse
VALUES(104, 'Lucy Fullbuster', 'Nurse', true, 444444440)
ON CONFLICT (employeeid) 
DO UPDATE SET name = EXCLUDED.name;





------------****-----------> 9. Transactions <-----------****-----------
BEGIN;

	INSERT INTO nurse VALUES (106, 'Vivian Bullwinkel', 'Intern Nurse', false, 666666660);

ROLLBACK;


SELECT * FROM nurse;


BEGIN WORK;

	INSERT INTO nurse VALUES (106, 'Vivian Bullwinkel', 'Intern Nurse', false, 666666660);

COMMIT TRANSACTION;





------------****-----------> 10. Managing Tables <-----------****-----------
CREATE SEQUENCE table_name_id_seq
START 1
INCREMENT 1
MINVALUE 0
OWNED BY datatype_demo.cust_ser_dt;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE EXTENSION hstore;

CREATE DOMAIN CUSTOM_DATATYPE AS VARCHAR NOT NULL CHECK (value !~ '\s');

CREATE TABLE datatype_demo (
	uuid_dt UUID DEFAULT uuid_generate_v4(),
	ser_dt SERIAL,
	cust_ser_dt INTEGER DEFAULT nextval('table_name_id_seq'),
	int_dt INT,
	num_dt NUMERIC(5,2),
    small_int_dt SMALLINT,
	boolean_dt BOOLEAN,
	char_dt CHAR (1),
	varchar_dt VARCHAR (10),
	text_dt TEXT,
	date_dt DATE,
    time_dt TIME,
	ts_dt TIMESTAMP, 
    tstz_dt TIMESTAMPTZ,
	json_dt json NOT NULL,
	hstore_dt hstore,
	arr_dt TEXT [],
    cust_dt CUSTOM_DATATYPE	
);

INSERT INTO datatype_demo (json_dt, hstore_dt, arr_dt, cust_dt)
VAlUES (
	'{ "ABC": "abc", "DEF": {"GHI": "ghi", "JKL": 6}}',
	'"XYZ" => "243", "UVW" => "uvw"',
	ARRAY ['hello','world!'],
	'User_Defined_Datatype'
);

SELECT * FROM datatype_demo;


SELECT uuid_dt, arr_dt, cust_dt
INTO TABLE dt_demo_subset
FROM datatype_demo
WHERE text_dt IS NULL;

SELECT * FROM dt_demo_subset;


CREATE TEMP TABLE dt_demo_sub_2 (a, b, c) 
AS 
SELECT uuid_dt, arr_dt, cust_dt
FROM datatype_demo
WHERE text_dt IS NULL;

SELECT * FROM dt_demo_sub_2;


ALTER TABLE dt_demo_sub_2 
ADD COLUMN d INT;

UPDATE dt_demo_sub_2 SET d = 1;

ALTER TABLE dt_demo_sub_2 
ALTER COLUMN d SET NOT NULL;

ALTER TABLE dt_demo_sub_2 
ALTER COLUMN d ADD GENERATED ALWAYS AS IDENTITY;

ALTER TABLE dt_demo_sub_2 
DROP COLUMN d;

ALTER TABLE dt_demo_sub_2 RENAME TO rename_2;

SELECT * FROM rename_2;

DROP TABLE IF EXISTS re2, rename_2;

TRUNCATE TABLE dt_demo_subset;





------------****-----------> 11. Constraints <-----------****-----------
CREATE TABLE constraints_demo (
	uid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
	email VARCHAR(20) UNIQUE,
	birth_date DATE CHECK (birth_date > '1900-01-01') NOT NULL
);

CREATE TABLE foreign_demo (
	name VARCHAR(20), 
	mail_id VARCHAR(20),
	CONSTRAINT fk_mail_id
		FOREIGN KEY(mail_id) 
	  	REFERENCES constraints_demo(email)
);





------------****-----------> 12. Conditional expressions and operators <-----------****-----------
SELECT mov_title,
       mov_year,
       CASE
           WHEN mov_year> 1950 AND mov_year <= 1980 THEN 'Old'
           WHEN mov_year > 1980 AND mov_year <= 2000 THEN 'Medium'
           WHEN mov_year> 2000 THEN 'New'
       END status
FROM movie
ORDER BY mov_title;


SELECT NULLIF(1, 1); -- return NULL

SELECT NULLIF(1, 0); -- return 1

SELECT NULLIF('A', 'B'); -- return A


SELECT 10 / COALESCE(NULLIF(0, 0), 2);


SELECT CAST ('109' AS INTEGER);





------------****-----------> 13. Compare two tables <-----------****-----------
SELECT uuid_dt, arr_dt, cust_dt FROM datatype_demo
EXCEPT
SELECT uuid_dt, arr_dt, cust_dt FROM dt_demo_subset;


SELECT COUNT(*)
FROM datatype_demo
FULL OUTER JOIN dt_demo_subset USING (uuid_dt);





------------****-----------> 14. Delete duplicate data <-----------****-----------
DELETE FROM datatype_demo a
USING datatype_demo b
WHERE a.ser_dt > b.ser_dt AND a.arr_dt = b.arr_dt;


DELETE FROM datatype_demo
WHERE arr_dt IN (
	SELECT arr_dt
    FROM (
		SELECT arr_dt, ROW_NUMBER() OVER( PARTITION BY varchar_dt) AS row_num
        FROM datatype_demo 
	) x
    WHERE x.row_num > 1 
);
		

SELECT DISTINCT * INTO re2 from dt_demo_subset;

DELETE FROM dt_demo_subset;

INSERT INTO dt_demo_subset (SELECT * FROM re2);

DROP TABLE re2;





------------****-----------> 15. Generate random number in a range <-----------****-----------
SELECT ceil(random() * 10)::int;











---------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------PL/PGSQL--------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------

------------****-----------> 1. Variable and constants <-----------****-----------
DO
$$
DECLARE
	rec RECORD;
BEGIN
	SELECT examinationroom, count(DISTINCT patient) "total_patient"
	INTO rec
	FROM appointment
	GROUP BY examinationroom
	LIMIT 1;
	
	raise notice '% has % patient', rec.examinationroom, rec.total_patient;   
END;
$$
LANGUAGE plpgsql;



DO $$ 
DECLARE
   pi COnSTANT NUMERIC := 3.14;
   radii NUMERIC := 1;
BEGIN
   RAISE NOTICE 'Area of circle is %', pi * POWER(radii,2);
END $$;





-----------****-----------> 2. Reporting message and errors  <-----------****-----------
DO $$ 
BEGIN
  RAISE INFO 'This is information message %', now() ;
  RAISE LOG 'This is log message %', now();
  RAISE DEBUG 'This is debug message %', now();
  RAISE WARNING 'This is warning message %', now();
  RAISE NOTICE 'This is notice message %', now();
END $$;


DO
$$
DECLARE
	tot_pat INT;
BEGIN
	SELECT count(DISTINCT patient) AS "total_patient"
	INTO tot_pat
	FROM appointment
	GROUP BY examinationroom
	ORDER BY count(DISTINCT patient) ASC
	LIMIT 1;
	
	assert tot_pat<2, 'All rooms are full '||tot_pat;   
END;
$$
LANGUAGE plpgsql;






-----------****-----------> 3. Control structure <-----------****-----------
DO
$$
DECLARE
	tot_pat INT;
BEGIN	
	SELECT count(DISTINCT patient) AS "total_patient"
	INTO tot_pat
	FROM appointment
	GROUP BY examinationroom
	ORDER BY count(DISTINCT patient) ASC
	LIMIT 1;
	
	IF FOUND THEN
		CASE
			WHEN tot_pat>=3 THEN RAISE NOTICE 'All rooms are full.';
			WHEN tot_pat<3 THEN RAISE NOTICE 'Not all rooms are filled yet.';
			ELSE RAISE NOTICE 'UNKNOWN SITUATION';
		END CASE;
	ELSE
		RAISE NOTICE 'No records found.';
	END IF;	
END;
$$
LANGUAGE plpgsql;



DO $$
DECLARE
   	counter int = 0;
BEGIN  
	LOOP
		counter = counter + 1;
		EXIT WHEN counter > 10;

		CONTINUE WHEN NOT (MOD(counter, 2) = 0 OR MOD(counter, 3) = 0);

		RAISE NOTICE '%', counter;
	END LOOP; 
END $$;



DO $$
DECLARE
   	counter integer := 2;
BEGIN
   	WHILE counter < 5 LOOP
      	RAISE NOTICE 'Counter %', counter;
	  	counter := counter + 1;
   	END LOOP;
END $$;



DO $$
DECLARE
    rec record;
BEGIN
    FOR rec IN SELECT COUNT(patient) "tot_pat", physician
	       FROM undergoes 
		   GROUP BY physician
	       ORDER BY tot_pat
	       limit 3 
    LOOP 
	RAISE NOTICE 'Physician % has % patient', rec.physician, rec.tot_pat;
    END LOOP;
END $$;





-----------****-----------> 4. User-defined function <-----------****-----------
SELECT gen_id, COUNT(mov_id) "total_movie"
FROM movie_genres
GROUP BY gen_id
HAVING COUNT(DISTINCT mov_id) > 2;


CREATE OR REPLACE FUNCTION genre_film_count(genre INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE 
	film_count INT;
BEGIN
  	SELECT COUNT(mov_id) "total_movie" INTO film_count
	FROM movie_genres
	GROUP BY gen_id
	HAVING gen_id = genre;
	
	RETURN film_count;
END;$$

SELECT * FROM genre_film_count(1007);




CREATE OR REPLACE FUNCTION most_movie_genre(
    OUT genre varchar,
    OUT film_count int)
LANGUAGE plpgsql
AS $$
BEGIN
  	SELECT gen_title, COUNT(mov_id) into genre, film_count 
	FROM genres 
	NATURAL JOIN movie_genres 
	GROUP BY gen_id 
	ORDER BY COUNT(mov_id) DESC 
	LIMIT 1;
END;$$

SELECT * FROM most_movie_genre();




CREATE OR REPLACE FUNCTION genre_film_count_inout(INOUT genre INT)
LANGUAGE plpgsql
AS $$
BEGIN
  	SELECT COUNT(mov_id) "total_movie" INTO genre
	FROM movie_genres
	GROUP BY gen_id
	HAVING gen_id = genre;
END;$$

SELECT * FROM genre_film_count_inout(1007);





CREATE OR REPLACE FUNCTION get_movies()
RETURNS TABLE (movie_id INT, movie_title character(50), movie_year INT) 
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
		SELECT mov_id, mov_title, mov_year
		FROM movie
		ORDER BY mov_year;
END; $$

select * from get_movies();




CREATE OR REPLACE FUNCTION get_movies(m_year INT)
RETURNS TABLE (movie_id INT, movie_title character(50), movie_year INT) 
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
		SELECT mov_id, mov_title, mov_year
		FROM movie
		WHERE mov_year>m_year
		ORDER BY mov_year;
END; $$

select * from get_movies(2000);


DROP FUNCTION get_movies(INT);






------------****-----------> 5. Store procedures <-----------****-----------
CREATE OR REPLACE PROCEDURE insert_nurse(
	e_id INT,
	name TEXT, 
	pos TEXT,
	registered BOOLEAN,
	ssn INT
)
LANGUAGE plpgsql    
AS $$
BEGIN
    INSERT INTO nurse
	VALUES	(e_id, name, pos, registered, ssn);

    COMMIT;
END;$$

CALL insert_nurse(107, 'Kate Marsden', 'Nurse', false, 777777770);

SELECT * FROM nurse;

DROP PROCEDURE IF EXISTS insert_nurse;







------------****-----------> 6. Exception handling <-----------****-----------
DO $$
DECLARE
	rec record;
	physician_id int = 7;
BEGIN
	SELECT patient, procedure, stay 
	INTO STRICT rec
	FROM undergoes
	WHERE physician = physician_id;
	
	EXCEPTION 
		WHEN SQLSTATE 'P0002' THEN 
	      	RAISE EXCEPTION 'No patient found under physician with id %', physician_id;
	   	WHEN too_many_rows THEN 
	    	RAISE EXCEPTION 'Multiple patient found under physician with id %', physician_id;
END $$;








------------****-----------> 7. Cursors <-----------****-----------
CREATE OR REPLACE FUNCTION get_nurse(pos TEXT)
   	RETURNS TEXT[] as $$
DECLARE 
	names TEXT[];
	rec RECORD;
	cur CURSOR(pos TEXT) FOR
		SELECT *
		FROM nurse
		WHERE position = pos;
BEGIN
   	OPEN cur(pos);
	
   	LOOP
      	FETCH cur INTO rec;

		EXIT WHEN NOT FOUND;

        names := ARRAY_APPEND(names, rec.name);
   	END LOOP;
   
   	CLOSE cur;

   	RETURN names;
END; $$
LANGUAGE plpgsql;

SELECT UNNEST(get_nurse('Nurse')) AS nurse_name;





------------****-----------> 8. Trigger functions <-----------****-----------
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


INSERT INTO reservation VALUES(5, 16, '18-01-2023');

UPDATE reservation SET inventory_id = 20 WHERE customer_id = 5;

DELETE FROM reservation WHERE customer_id = 5;





------------****-----------> 9. Aggregate Function <-----------****-----------
SELECT 
	gen_title, 
	COUNT(mov_id) AS total_movie,
	AVG(mov_time)::NUMERIC(6, 2) AS avg_movie_time,
	SUM(mov_time) AS total_movie_time,
	MAX(mov_time) AS max_movie_time,
	MIN(mov_time) AS min_movie_time
FROM movie 
JOIN movie_genres USING (mov_id)
JOIN genres USING (gen_id)
GROUP BY gen_title;


SELECT * FROM nurse;

SELECT 
	position, 
	ARRAY_AGG(
		employeeid::TEXT || ': ' || name
		ORDER BY employeeid
	) AS arr,
	STRING_AGG (
		employeeid::TEXT || ': ' || name,
        ' --- '
       	ORDER BY employeeid
    ) AS str
FROM nurse
GROUP BY position;



CREATE TABLE ranks (
	user_id INT PRIMARY KEY,
	rank_1 int4 NOT NULL,
	rank_2 int4 NOT NULL,
	rank_3 int4 NOT NULL
);

INSERT INTO ranks
VALUES
	(1, 6, 3, 5),
	(2, 2, 8, 5),
	(3, 5, 9, 8);

SELECT
	user_id,
	LEAST (rank_1, rank_2, rank_3) AS lowest_rank,
	GREATEST (rank_1, rank_2, rank_3) AS highest_rank
FROM
	ranks;





------------****-----------> 10. Window Function <-----------****-----------
SELECT * FROM movie;

SELECT
	mov_title, gen_id, mov_time,
	RANK() OVER w,
	DENSE_RANK() OVER w,
	ROW_NUMBER() OVER w
FROM movie
NATURAL JOIN movie_genres
WINDOW w AS (PARTITION BY gen_id ORDER BY mov_time);


SELECT
	mov_title, gen_id, mov_time,
	COALESCE(ROUND((mov_time - LAG(mov_time,1) OVER w) * 100 / mov_time, 2) , 0) || '%' AS "time_inc_%",
	COALESCE(ROUND((mov_time - LEAD(mov_time,1) OVER w) * 100 / mov_time, 2) , 0) || '%' AS "time_dec_%"
FROM movie
NATURAL JOIN movie_genres
WINDOW w AS (PARTITION BY gen_id ORDER BY mov_time);


SELECT 
	mov_title, gen_id, mov_time,
	FIRST_VALUE(mov_title) OVER w AS highest_mov_time,
	LAST_VALUE(mov_title) OVER w AS least_mov_time,
	NTH_VALUE(mov_title, 2) OVER w AS second_most_mov_time
FROM movie
NATURAL JOIN movie_genres
WINDOW w AS (
	PARTITION BY gen_id ORDER BY mov_time DESC
	RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
);
			


WITH cte AS(
	SELECT *,
    NTILE(2) OVER (ORDER BY mov_time DESC) AS time_bucket
    FROM movie
	NATURAL JOIN movie_genres
	WHERE gen_id = 1007
)
select mov_title, mov_time,
	CASE 
		WHEN time_bucket = 1 THEN 'Long movie'
		WHEN time_bucket = 2 THEN 'Short movie' 
	END AS Movie_Category
from cte;



SELECT mov_title, "time_cume_dist_%" || '%' AS "time_cume_dist_%", time_percentile_rank
FROM (
    SELECT *,
		ROUND(CUME_DIST() OVER (ORDER BY mov_time DESC)::NUMERIC * 100,2) AS "time_cume_dist_%",
		ROUND(PERCENT_RANK() OVER(ORDER BY mov_time ASC)::NUMERIC * 100,2) AS time_percentile_rank
    from movie) x
WHERE x."time_cume_dist_%" <= 40 OR time_percentile_rank <=40;


SELECT mov_title, time_percentile_rank
FROM (
    SELECT *,
		ROUND(PERCENT_RANK() OVER(ORDER BY mov_time ASC)::NUMERIC * 100,2) AS time_percentile_rank
    from movie) x
WHERE mov_title = 'Slumdog Millionaire';





------------****-----------> 11. Date Function <-----------****-----------
SELECT
	AGE(NOW())
	CURRENT_DATE, 
	CURRENT_TIME, 
	CURRENT_TIME(3) "cur_time_with_presicion",
	CURRENT_TIMESTAMP(3) "cur_ts_with_presicion",
	DATE_PART('century',CURRENT_TIMESTAMP) "century",
	DATE_PART('doy',NOW()) "day_of_year",
	LOCALTIME,
	LOCALTIMESTAMP(3),
	EXTRACT(QUARTER FROM NOW()) "quarter",
	EXTRACT(DECADE FROM NOW()) "decade",
	EXTRACT(MILLISECONDS FROM INTERVAL '6 years 5 months 4 days 3 hours 2 minutes 1 second') "ms",
	TO_DATE('30 JAN 2023', 'DD MON YYYY'),
	TO_TIMESTAMP('Jan     2023 12:30','FXMon     YYYY HH:MI'),
	(NOW() + interval '1 day 1 hour') AS an_hour_later_tomorrow,
	TIMEOFDAY(),
	DATE_TRUNC('year', NOW()) y;





------------****-----------> 12. String Function <-----------****-----------
SELECT
	ASCII('XYZ') "ascii_of_x",
	CHR(77) "chr(77)",
	LOWER('qWeRtY'),
	UPPER('qWeRtY'),
	INITCAP('qWeRtY'),
	POSITION('et' IN 'sweet etetet'),
	SUBSTRING('ABCDEFGHIJKLM' FROM 2),
	SUBSTRING('ABCDEFGHIJKLM' FROM 2 FOR 4),
	SUBSTRING('ABCDEFGHIJKLM', 2, 4),
	SUBSTRING('AB CDE FGHIJKLM' FROM '([A-Z]{3})'),
	SPLIT_PART(NOW()::TEXT, '-', 2),
	REPLACE('QWETRY', 'TR', 'RT'),
	TRANSLATE('LÒ BÓ VÔ XÕ', 'ÒÓÔÕ', 'OOO'),
	REGEXP_REPLACE('+91 7865412398', '^[+][0-9]{2}', '+0'),
	REGEXP_REPLACE('ABC12345xyz','[[:alpha:]]','','g'),
	LENGTH('asdfghjkl132'),
	TRIM(LEADING FROM '  PostgreSQL TRIM   '),
	TRIM(TRAILING '.' FROM '  PostgreSQL TRIM....'),
	RTRIM('RTRIM#####', '#'),
	TRIM ('  PostgreSQL TRIM  '),
	FORMAT('|%-8s|', 'one'),
	LPAD('one',8,'*'),
	RPAD('one',8,'*'),
	FORMAT('%1$s, %2$s and %1$s', 'one', 'two'),
	MD5('QWERTY'),
	LEFT('QWERTY', 3),
	RIGHT('QWERTY', 3),
	CONCAT('Concat with ', NULL, 'NULL'),
	CONCAT_WS(', ', 'abc', 'def'),
	TO_CHAR(NOW(), 'MON-DD-YYYY HH12:MIPM'),
	TO_NUMBER('$12,34,567.89','L9g999G999.99');





------------****-----------> 13. Math Function <-----------****-----------
SELECT
	ROUND(13.13 * 13.13, 2),
	ABS(-1 * 2),
	CEIL(101.2),
	FLOOR(101.2),
	MOD(10, 2),
	TRUNC(150.45,-2);











---------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------PostgreSQL administration----------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------

------------****-----------> 1. Managing database <-----------****-----------
CREATE DATABASE test 
WITH 
   ENCODING = 'UTF8'
   OWNER = postgres
   CONNECTION LIMIT = 100;
   
   
ALTER DATABASE test 
RENAME TO test_rn;


SELECT *
FROM pg_stat_activity
WHERE datname = 'test_rn';


SELECT	pg_terminate_backend (pid)
FROM	pg_stat_activity
WHERE	pg_stat_activity.datname = 'test_rn';


DROP DATABASE test_rn;


SELECT pg_terminate_backend (pid)
FROM pg_stat_activity
WHERE datname = 'demo';


CREATE DATABASE demo_test 
WITH TEMPLATE demo;

SELECT pg_size_pretty (pg_relation_size('demo_test'));

SELECT
    pg_database.datname,
    pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database;

select pg_column_size(5::int);






------------****-----------> 2. Managing schema <-----------****-----------
select pg_relation_size('product');


SELECT current_schema();


CREATE SCHEMA test;


SHOW search_path;


SET search_path TO test, public;


CREATE TABLE staff(
    staff_id SERIAL PRIMARY KEY,
    first_name VARCHAR(45) NOT NULL,
    last_name VARCHAR(45) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE
);


SELECT current_schema();

ALTER SCHEMA test
RENAME TO rename_test;

DROP SCHEMA rename_test CASCADE;





------------****-----------> 3. Managing tablespaces <-----------****-----------
CREATE TABLESPACE test_ts LOCATION '/home/shubham/Desktop/tblspace';

SELECT pg_size_pretty (pg_tablespace_size('pg_default'));





------------****-----------> 4. Role and privileges <-----------****-----------
CREATE ROLE test_role 
LOGIN
PASSWORD '132456789';

CREATE SCHEMA AUTHORIZATION test_role;

CREATE ROLE new_user 
SUPERUSER 
LOGIN 
PASSWORD '987654321'
VALID UNTIL '2023-02-01'
CONNECTION LIMIT 999;


SELECT rolname FROM pg_roles;

GRANT INSERT, UPDATE, DELETE ON products 
TO test_role;

GRANT ALL ON ALL TABLES
IN SCHEMA "public"
TO new_user;


REVOKE DELETE ON products
FROM test_role;


ALTER ROLE test_role SUPERUSER;


CREATE ROLE grp_role;

GRANT grp_role TO test_role;
GRANT grp_role TO test_user;

REVOKE grp_role FROM test_user;


GRANT INSERT, UPDATE, DELETE ON nurse 
TO grp_role;

DROP ROLE test_role;


SELECT usename AS role_name,
  CASE 
     WHEN usesuper AND usecreatedb THEN 
	   CAST('superuser, create database' AS pg_catalog.text)
     WHEN usesuper THEN 
	    CAST('superuser' AS pg_catalog.text)
     WHEN usecreatedb THEN 
	    CAST('create database' AS pg_catalog.text)
     ELSE 
	    CAST('' AS pg_catalog.text)
  END role_attributes
FROM pg_catalog.pg_user
ORDER BY role_name desc;