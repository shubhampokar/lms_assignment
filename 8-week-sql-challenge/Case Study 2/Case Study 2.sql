CREATE SCHEMA pizza_runner;
GO

DROP TABLE IF EXISTS pizza_runner.runners;
CREATE TABLE pizza_runner.runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO pizza_runner.runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');
GO

DROP TABLE IF EXISTS pizza_runner.customer_orders;
CREATE TABLE pizza_runner.customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" DATETIME
);

INSERT INTO pizza_runner.customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');
GO


DROP TABLE IF EXISTS pizza_runner.runner_orders;
CREATE TABLE pizza_runner.runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO pizza_runner.runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');
GO


DROP TABLE IF EXISTS pizza_runner.pizza_names;
CREATE TABLE pizza_runner.pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_runner.pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');
GO


DROP TABLE IF EXISTS pizza_runner.pizza_recipes;
CREATE TABLE pizza_runner.pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_runner.pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');
GO


DROP TABLE IF EXISTS pizza_runner.pizza_toppings;
CREATE TABLE pizza_runner.pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_runner.pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
GO









--------------------------------------------------------- DATA CLEANING ------------------------------------------------------

---> The exclusions and extras columns will need to be cleaned up before using them in your queries.
---> Cleaning exclusions and extras.
UPDATE [pizza_runner].[customer_orders]
SET exclusions = (
		CASE
			WHEN exclusions='null' OR exclusions='' THEN NULL
			ELSE exclusions
		END
	),
	extras = (
		CASE
			WHEN extras='null' OR extras='' THEN NULL
			ELSE extras
		END
	);
GO

--- checking changes
SELECT * FROM [pizza_runner].[customer_orders];
GO




------------------------ Checking which method works best

----- method 1 ------------- using stuff() ----------- relative cost: 50 ------------------

--CREATE OR ALTER FUNCTION [pizza_runner].[getNumeric] (@InputString VARCHAR(MAX)) 
--RETURNS VARCHAR(MAX) 
--AS 
--BEGIN 
--    WHILE PATINDEX('%[^0-9(.)0-9]%', @InputString) <> 0 
--    BEGIN 
--        SET @InputString = STUFF(@InputString, PATINDEX('%[^0-9(.)0-9]%', @InputString),1, '') 
--    END 

--    RETURN @InputString 
--END
--GO

--SET STATISTICS IO ON;
--SET STATISTICS TIME ON;
--GO

--SELECT *,
--	CASE 
--		WHEN distance='null' OR distance='' THEN NULL
--		ELSE [pizza_runner].[getNumeric](distance)
--	END,
--	CASE 
--		WHEN duration='null' OR duration='' THEN NULL
--		ELSE [pizza_runner].[getNumeric](duration)
--	END 
--FROM [pizza_runner].[runner_orders];
--GO



----- method 2 -------- using substring() ----------- relative cost: 50 ------------------

--SELECT *,
--	--COALESCE(NULLIF(PATINDEX('%[^0-9(.)]%', distance), 0), LEN(distance)),
--	--PATINDEX('%[0-9]%', distance),
--	--COALESCE(NULLIF(PATINDEX('%[^0-9(.)]%', distance), 0), LEN(distance)+1) - PATINDEX('%[0-9]%', distance),
--	CASE 
--		WHEN distance='null' OR distance='' THEN NULL
--		ELSE SUBSTRING(distance, PATINDEX('%[0-9]%', distance), COALESCE(NULLIF(PATINDEX('%[^0-9(.)]%', distance), 0), LEN(distance)+1) - PATINDEX('%[0-9]%', distance))
--	END,
--	CASE 
--		WHEN duration='null' OR duration='' THEN NULL
--		ELSE SUBSTRING(duration, PATINDEX('%[0-9]%', duration), COALESCE(NULLIF(PATINDEX('%[^0-9(.)]%', duration), 0), LEN(duration)+1) - PATINDEX('%[0-9]%', duration))
--	END
--FROM [pizza_runner].[runner_orders];
--GO


--SET STATISTICS IO OFF;
--SET STATISTICS TIME OFF;
--GO


UPDATE [pizza_runner].[runner_orders] 
SET distance = (
		CASE 
			WHEN distance='null' OR distance='' THEN NULL
			ELSE SUBSTRING(distance, PATINDEX('%[0-9]%', distance), COALESCE(NULLIF(PATINDEX('%[^0-9(.)]%', distance), 0), LEN(distance)+1) - PATINDEX('%[0-9]%', distance))
		END
	),
	duration = (
		CASE 
			WHEN duration='null' OR duration='' THEN NULL
			ELSE SUBSTRING(duration, PATINDEX('%[0-9]%', duration), COALESCE(NULLIF(PATINDEX('%[^0-9(.)]%', duration), 0), LEN(duration)+1) - PATINDEX('%[0-9]%', duration))
		END
	),
	pickup_time = (
		CASE 
			WHEN pickup_time='null' OR pickup_time='' THEN NULL
			ELSE pickup_time
		END
	),
	cancellation = (
		CASE 
			WHEN cancellation='null' OR cancellation='' THEN NULL
			ELSE cancellation
		END
	);

ALTER TABLE [pizza_runner].[runner_orders]
ALTER COLUMN distance REAL;
ALTER TABLE [pizza_runner].[runner_orders]
ALTER COLUMN duration REAL;

SELECT * FROM [pizza_runner].[runner_orders];
GO



--- view for pizza_recipe table
CREATE VIEW pizza_runner.pizza_recipe_view
AS
	SELECT pizza_id, CAST(value AS INT) AS "topping_id"
	FROM [pizza_runner].[pizza_recipes]
	CROSS APPLY STRING_SPLIT(CAST(toppings AS NVARCHAR(30)), ',');
GO



--- changing column text datatype to nvarchar because text can be use in comparison
ALTER TABLE [pizza_runner].[pizza_toppings]
ALTER COLUMN topping_name NVARCHAR(30);
GO


ALTER TABLE [pizza_runner].[pizza_names]
ALTER COLUMN pizza_name NVARCHAR(30);
GO


ALTER TABLE [pizza_runner].[pizza_recipes]
ALTER COLUMN toppings NVARCHAR(50);
GO


















--------------------------------------------------------------------------------------------------> A. Pizza Metrics <--------------------------------------------------------------------------------------------------
---> 1) How many pizzas were ordered?
SELECT COUNT(*) AS "total_pizza_ordered"
FROM [pizza_runner].[customer_orders];
GO





---> 2) How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS "unique_customer_orders"
FROM [pizza_runner].[customer_orders];
GO





---> 3) How many successful orders were delivered by each runner?
SELECT 
	runner_id, 
	COUNT(*) AS "successful_delivery_count"
FROM [pizza_runner].[runner_orders]
WHERE cancellation IS NULL
GROUP BY runner_id;
GO




---> 4) How many of each type of pizza was delivered?
SELECT 
	pizza_id, 
	COUNT(*) AS "order_count"
FROM [pizza_runner].[customer_orders] co
JOIN [pizza_runner].[runner_orders] pn
	ON co.order_id = pn.order_id
WHERE cancellation IS NULL
GROUP BY pizza_id;
GO




---> 5) How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
	customer_id, 
	pizza_name,
	COUNT(*) AS "order_count"
FROM [pizza_runner].[customer_orders] co
JOIN [pizza_runner].[pizza_names] pn
	ON co.pizza_id = pn.pizza_id
GROUP BY customer_id, pizza_name
ORDER BY customer_id;
GO




---> 6) What was the maximum number of pizzas delivered in a single order?
WITH pizza_order_cte AS (
	SELECT 
		co.order_id, 
		COUNT(*) AS "order_count"
	FROM [pizza_runner].[customer_orders] co
	JOIN [pizza_runner].[runner_orders] pn
		ON co.order_id = pn.order_id
	WHERE cancellation IS NULL
	GROUP BY co.order_id
)
SELECT 
	MAX(order_count) AS "max_pizza_ordered"
FROM pizza_order_cte;
GO




---> 7) For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
	customer_id,
	SUM(
		CASE
			WHEN exclusions IS NULL AND extras IS NULL THEN 0
			ELSE 1
		END
	) AS "total_pizza_with_changes",
	SUM(
		CASE
			WHEN exclusions IS NULL AND extras IS NULL THEN 1
			ELSE 0
		END
	) AS "total_pizza_with_changes_no_changes"
FROM [pizza_runner].[customer_orders] co
JOIN [pizza_runner].[runner_orders] pn
	ON co.order_id = pn.order_id
WHERE cancellation IS NULL
GROUP BY customer_id;
GO




---> 8) How many pizzas were delivered that had both exclusions and extras?
SELECT 
	SUM(
		CASE
			WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 1
			ELSE 0
		END
	) AS "total_pizza_with_exclusion_n_extra"
FROM [pizza_runner].[customer_orders] co
JOIN [pizza_runner].[runner_orders] pn
	ON co.order_id = pn.order_id
WHERE cancellation IS NULL;
GO




---> 9) What was the total volume of pizzas ordered for each hour of the day?
SELECT (DATEPART(HOUR, order_time)) AS "hour", COUNT(*) "total_order"
FROM [pizza_runner].[customer_orders]
GROUP BY (DATEPART(HOUR, order_time));
GO




---> 10) What was the volume of orders for each day of the week?
--set datefirst 1;

SELECT (DATENAME(WEEKDAY, order_time)) AS "day_of_week", COUNT(*) "total_order"
FROM [pizza_runner].[customer_orders]
GROUP BY (DATENAME(WEEKDAY, order_time));
GO


SELECT (DATEPART(WEEKDAY, order_time)) AS "day_no_of_week", COUNT(*) "total_order"
FROM [pizza_runner].[customer_orders]
GROUP BY (DATEPART(WEEKDAY, order_time));
GO


--SELECT DATEPART(WEEKDAY, GETDATE())

--SELECT @@DATEFIRST;
GO

















------------------------------------------------------------------------------------------> B. Runner and Customer Experience <------------------------------------------------------------------------------------------
---> 1) How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT 
	DATE_BUCKET(WEEK, 1, registration_date, CAST('2021-01-01' AS DATE)) AS "week_start_date",
	DATEPART(WEEK, DATE_BUCKET(WEEK, 1, registration_date, CAST('2021-01-01' AS DATE))) AS "week_no",
	COUNT(*) "total_order"
FROM [pizza_runner].[runners]
GROUP BY 
	DATE_BUCKET(WEEK, 1, registration_date, CAST('2021-01-01' AS DATE)),
	DATEPART(WEEK, DATE_BUCKET(WEEK, 1, registration_date, CAST('2021-01-01' AS DATE)));
GO





---> 2) What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

--- method 1 - taking seconds into consideration
SELECT 
	runner_id,
	ROUND(
		AVG(
			DATEPART(HOUR,(pickup_time-order_time))*60 
			+ 
			DATEPART(MINUTE,(pickup_time-order_time)) 
			+ 
			CAST(DATEPART(SECOND,(pickup_time-order_time)) AS REAL)/60
		),
		2
	) AS "avg_pickup_time"
FROM [pizza_runner].[customer_orders] co
JOIN [pizza_runner].[runner_orders] pn
	ON co.order_id = pn.order_id
WHERE cancellation IS NULL
GROUP BY runner_id;
GO


-- method 2 - taking seconds into consideration
SELECT 
	runner_id,
	ROUND(
		AVG(
			CAST(DATEDIFF(SECOND, order_time, pickup_time) AS REAL)
		) / 60,
		2
	) AS "avg_pickup_time"
FROM [pizza_runner].[customer_orders] co
JOIN [pizza_runner].[runner_orders] pn
	ON co.order_id = pn.order_id
WHERE cancellation IS NULL
GROUP BY runner_id;
GO


-- without taking seconds into consideration
SELECT 
	runner_id,
	ROUND(
		AVG(
			CAST(DATEDIFF(MINUTE, order_time, pickup_time) AS REAL)
		),
		2
	) AS "avg_pickup_time"
FROM [pizza_runner].[customer_orders] co
JOIN [pizza_runner].[runner_orders] pn
	ON co.order_id = pn.order_id
WHERE cancellation IS NULL
GROUP BY runner_id;
GO






---> 3) Is there any relationship between the number of pizzas and how long the order takes to prepare?

-- there is no data regarding pizza preparation time
-- if the difference between pickup_time - order_time is preparation time then => [approx. 10 min to prepare a pizza]
-- OR
-- another conclusion can be: for	1 pizza per order: approx. preparation time = 12 min
--									2 pizza per order: approx. preparation time = 9 min
--									3 pizza per order: approx. preparation time = 10 min
WITH pizza_prep_cte AS (
	SELECT 
		co.order_id,
		count(*) AS "pizza_ordered",
		(pickup_time-order_time) AS "prep_time"
	FROM [pizza_runner].[customer_orders] co
	JOIN [pizza_runner].[runner_orders] pn
		ON co.order_id = pn.order_id
	WHERE cancellation IS NULL
	GROUP BY co.order_id,pickup_time,order_time
	--ORDER BY pizza_ordered
)
SELECT 
	pizza_ordered, 
	AVG(DATEPART(MINUTE, prep_time)) "avg_prep_time (min)"
FROM pizza_prep_cte
GROUP BY pizza_ordered;
GO


-- more precise
WITH pizza_prep_cte AS (
	SELECT 
		co.order_id,
		count(*) AS "pizza_ordered",
		DATEDIFF(SECOND, order_time, pickup_time) / 60.0 AS "prep_time"
	FROM [pizza_runner].[customer_orders] co
	JOIN [pizza_runner].[runner_orders] pn
		ON co.order_id = pn.order_id
	WHERE cancellation IS NULL
	GROUP BY co.order_id,pickup_time,order_time
	--ORDER BY pizza_ordered
)
SELECT 
	pizza_ordered, 
	AVG(prep_time) "avg_prep_time (min)"
FROM pizza_prep_cte
GROUP BY pizza_ordered;
GO





---> 4) What was the average distance travelled for each customer?
SELECT 
	customer_id, 
	ROUND(AVG(distance), 2) AS "avg_distance_travelled_by_runner (km)"
FROM [pizza_runner].[customer_orders] co
JOIN [pizza_runner].[runner_orders] pn
	ON co.order_id = pn.order_id
GROUP BY customer_id;
GO




---> 5) What was the difference between the longest and shortest delivery times for all orders?

-- considering only duration of travel
SELECT 
	(MAX(duration) - MIN(duration)) AS "longest_n_shortest_delivery_distance"
FROM [pizza_runner].[runner_orders];
GO


-- considering order_time, pickup_time and duration of travel
WITH delivery_time_cte AS (
	SELECT 
		DISTINCT co.order_id,
		(
			DATEPART(HOUR, (pickup_time-order_time))*60 
			+ 
			DATEPART(MINUTE, (pickup_time-order_time)) 
			+ 
			CAST(DATEPART(SECOND, (pickup_time-order_time)) AS REAL)/60
			+ 
			duration
		 )  AS "delivery_time"
	FROM [pizza_runner].[customer_orders] co
	JOIN [pizza_runner].[runner_orders] pn
		ON co.order_id = pn.order_id
	WHERE cancellation IS NULL
)
SELECT
	ROUND((MAX(delivery_time) - MIN(delivery_time)), 2) AS "longest_n_shortest_delivery_distance"
FROM delivery_time_cte;
GO




---> *6) What was the average speed for each runner for each delivery and do you notice any trend for these values?

-- avg speed for each delivery would be same as delivery time 
-- this query doesn't make any sense as well as it can't be use to find any trend 
-- this query is same as calculating speed for each order
SELECT 
	runner_id,
	order_id,
	AVG(duration) AS "avg_duration (min)",
	ROUND(AVG(distance), 2) AS "avg_distance (km)",
	ROUND(
		AVG(distance/(duration/60)),
		2
	) AS "avg_speed (kmph)"
FROM [pizza_runner].[runner_orders]
WHERE cancellation IS NULL
GROUP BY runner_id, order_id
ORDER by order_id;
GO
  

-- considering avg speed for all delivery by each runner
-- avg speed for	runner 1: 45.5 km/h
--					runner 2: 62.9 km/h
--					runner 3: 40 km/h
SELECT 
	runner_id,
	ROUND(
		AVG(distance/(duration/60)),
		2
	) AS "avg_speed (kmph)"
FROM [pizza_runner].[runner_orders]
WHERE cancellation IS NULL
GROUP BY runner_id;
GO

-- from below query, it can be concluded that
--		runner 1 -- duration increases exponentially (at small rate) as distance increases
--		runner 2 -- duration decreases exponentially (at small rate) as distance increases
--		runner 3 -- insufficient data
SELECT 
	runner_id,
	distance,
	AVG(duration) AS "avg_duration",
	ROUND(
		AVG(distance/(duration/60)),
		2
	) AS "avg_speed (kmph)"
FROM [pizza_runner].[runner_orders]
WHERE cancellation IS NULL
GROUP BY runner_id, distance
ORDER by distance;

GO




---> 7) What is the successful delivery percentage for each runner?

-- there is no reasons in cancellation column where it mentioned that it was cancelled due to runner
-- if we consider all cancellation reason as runner's success or failure
SELECT 
	runner_id,
	(
		CAST(
			SUM(
				CASE
					WHEN cancellation IS NULL THEN 1
					ELSE 0
				END
			)
			AS REAL
		) / COUNT(*)
	) * 100 AS "successful_delivery_percentage"
FROM [pizza_runner].[runner_orders]
GROUP BY runner_id;
GO
















---------------------------------------------------------------------------------------------> C. Ingredient Optimisation <---------------------------------------------------------------------------------------------
---> 1) What are the standard ingredients for each pizza?
SELECT pizza_name,
	STRING_AGG(topping_name, ', ') AS "standard_ingredients"
FROM [pizza_runner].[pizza_names] pn
JOIN [pizza_runner].[pizza_recipe_view] prv
	ON pn.pizza_id = prv.pizza_id
JOIN [pizza_runner].[pizza_toppings] pt
	ON prv.topping_id = pt.topping_id
GROUP BY pizza_name;
GO




---> 2) What was the most commonly added extra?

--- considering most frequent as most common (since most common depends on perspective, for some it might be top 1 or top 3 or top 5...)
SELECT TOP 1
	value AS "topping_id", 
	topping_name,
	COUNT(*) AS "total_count"
FROM [pizza_runner].[customer_orders]
CROSS APPLY STRING_SPLIT(extras, ',')
JOIN [pizza_runner].[pizza_toppings] pt
	ON pt.topping_id = value
GROUP BY value, topping_name
ORDER BY "total_count" DESC;
GO




---> 3) What was the most common exclusion?
SELECT TOP 1
	value AS "topping_id", 
	topping_name,
	COUNT(*) AS "total_count"
FROM [pizza_runner].[customer_orders]
CROSS APPLY STRING_SPLIT(exclusions, ',')
JOIN [pizza_runner].[pizza_toppings] pt
	ON pt.topping_id = value
GROUP BY value, topping_name
ORDER BY "total_count" DESC;
GO




---> 4) Generate an order item for each record in the customers_orders table in the format of one of the following:
--		Meat Lovers
--		Meat Lovers - Exclude Beef
--		Meat Lovers - Extra Bacon
--		Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers


GO
---- worst case scenario - checking different cases for toppings variable before creating function
--DECLARE @toppings NVARCHAR(30)
--SET @toppings = '11, 5,6,d 1, zc10,z7'
--SET @toppings = '@' + @toppings + ','

--SET @toppings = REPLACE(@toppings, ' ', '@')

--DECLARE @list NVARCHAR(300)
--SET @list = ''

--IF @toppings LIKE '%@1,%' OR @toppings LIKE '%[^0-9]1,%'
--	SET @list = @list + 'Bacon, '
--IF @toppings LIKE '%@2,%' OR @toppings LIKE '%[^0-9]2,%'
--	SET @list = @list + 'BBQ Sauce, '
--IF @toppings LIKE '%@3,%' OR @toppings LIKE '%[^0-9]3,%'
--	SET @list = @list + 'Beef, '
--IF @toppings LIKE '%@4,%' OR @toppings LIKE '%[^0-9]4,%'
--	SET @list = @list + 'Cheese, '
--IF @toppings LIKE '%@5,%' OR @toppings LIKE '%[^0-9]5,%'
--	SET @list = @list + 'Chicken, '
--IF @toppings LIKE '%@6,%' OR @toppings LIKE '%[^0-9]6,%'
--	SET @list = @list + 'Mushrooms, '
--IF @toppings LIKE '%@7,%' OR @toppings LIKE '%[^0-9]7,%'
--	SET @list = @list + 'Onions, '
--IF @toppings LIKE '%@8,%' OR @toppings LIKE '%[^0-9]8,%'
--	SET @list = @list + 'Pepperoni, '
--IF @toppings LIKE '%@9,%' OR @toppings LIKE '%[^0-9]9,%'
--	SET @list = @list + 'Peppers, '
--IF @toppings LIKE '%@10,%' OR @toppings LIKE '%[^0-9]10,%'
--	SET @list = @list + 'Salami, '
--IF @toppings LIKE '%@11,%' OR @toppings LIKE '%[^0-9]11,%'
--	SET @list = @list + 'Tomatoes, '
--IF @toppings LIKE '%@12,%' OR @toppings LIKE '%[^0-9]12,%'
--	SET @list = @list + 'Tomato Sauce, '

--PRINT 'This is bef list ' + @list

--SET @list = LEFT(@list, LEN(@list) - 2)

--PRINT @list + 'This is aft list'

GO

---- creating function to get toppings list

--CREATE OR ALTER FUNCTION [pizza_runner].[getToppings] (@toppings NVARCHAR(30))
--RETURNS NVARCHAR(300) AS
--BEGIN

--	SET @toppings = '@' + @toppings + ','
--	SET @toppings = REPLACE(@toppings, ' ', '@')

--	DECLARE @list NVARCHAR(300)
--	SET @list = ''

--	--IF @toppings LIKE '\b1(,)' 
--	--	SET @list = @list + 'Bacon, '

--	IF @toppings LIKE '%@1,%' OR @toppings LIKE '%[^0-9]1,%'
--		SET @list = @list + 'Bacon, '
--	IF @toppings LIKE '%@2,%' OR @toppings LIKE '%[^0-9]2,%'
--		SET @list = @list + 'BBQ Sauce, '
--	IF @toppings LIKE '%@3,%' OR @toppings LIKE '%[^0-9]3,%'
--		SET @list = @list + 'Beef, '
--	IF @toppings LIKE '%@4,%' OR @toppings LIKE '%[^0-9]4,%'
--		SET @list = @list + 'Cheese, '
--	IF @toppings LIKE '%@5,%' OR @toppings LIKE '%[^0-9]5,%'
--		SET @list = @list + 'Chicken, '
--	IF @toppings LIKE '%@6,%' OR @toppings LIKE '%[^0-9]6,%'
--		SET @list = @list + 'Mushrooms, '
--	IF @toppings LIKE '%@7,%' OR @toppings LIKE '%[^0-9]7,%'
--		SET @list = @list + 'Onions, '
--	IF @toppings LIKE '%@8,%' OR @toppings LIKE '%[^0-9]8,%'
--		SET @list = @list + 'Pepperoni, '
--	IF @toppings LIKE '%@9,%' OR @toppings LIKE '%[^0-9]9,%'
--		SET @list = @list + 'Peppers, '
--	IF @toppings LIKE '%@10,%' OR @toppings LIKE '%[^0-9]10,%'
--		SET @list = @list + 'Salami, '
--	IF @toppings LIKE '%@11,%' OR @toppings LIKE '%[^0-9]11,%'
--		SET @list = @list + 'Tomatoes, '
--	IF @toppings LIKE '%@12,%' OR @toppings LIKE '%[^0-9]12,%'
--		SET @list = @list + 'Tomato Sauce, '

--	SET @list = LEFT(@list, LEN(@list) - 1)

--	--RAISERROR(@list, 0, 1)

--    RETURN @list
--END;
GO

---- method 1 solution using getToppings() function
--SELECT co.*, 
--	CASE
--		WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN pizza_name + ' - Exclude ' + [pizza_runner].[getToppings](exclusions) + ' - Extra ' + [pizza_runner].[getToppings](extras)
--		WHEN exclusions IS NOT NULL THEN pizza_name + ' - Exclude ' + [pizza_runner].[getToppings](exclusions)
--		WHEN extras IS NOT NULL THEN pizza_name + ' - Extra ' + [pizza_runner].[getToppings](extras)
--		ELSE pizza_name
--	END AS "pizza_order_detail"
--FROM [pizza_runner].[customer_orders] co
--JOIN [pizza_runner].[pizza_names] pn
--	ON co.pizza_id = pn.pizza_id;
GO


---- method 2 using order_ingredients() (upgraded version of getToppings() function) function
SELECT co.*, 
	CASE
		WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN pizza_name + ' - Exclude ' + [pizza_runner].[order_ingredients](exclusions, NULL, 0, NULL) + ' - Extra ' + [pizza_runner].[order_ingredients](NULL, extras, 1, NULL)
		WHEN exclusions IS NOT NULL THEN pizza_name + ' - Exclude ' + [pizza_runner].[order_ingredients](exclusions, NULL, 0, NULL)
		WHEN extras IS NOT NULL THEN pizza_name + ' - Extra ' + [pizza_runner].[order_ingredients](NULL, extras, 1, NULL)
		ELSE pizza_name
	END AS "pizza_order_detail"
FROM [pizza_runner].[customer_orders] co
JOIN [pizza_runner].[pizza_names] pn
	ON co.pizza_id = pn.pizza_id;
GO

---- Normal regex features doesn't work with like clause (here, word boundary metacharacter [ \b ] doesn't work)
--SELECT *,
--	CASE 
--		WHEN extras LIKE '\b1(,)' THEN 'Bacon'
--		WHEN extras LIKE '\b2(,)' THEN 'BBQ Sauce'
--		WHEN extras LIKE '\b3(,)' THEN 'Beef'
--		WHEN extras LIKE '\b4(,)' THEN 'Cheese'
--		WHEN extras LIKE '\b5(,)' THEN 'Chicken'
--		WHEN extras LIKE '\b6(,)' THEN 'Mushrooms'
--	END
--FROM [pizza_runner].[customer_orders]
--WHERE order_id = 9;
GO


---- solutions based on datatype of exclusions and extras
---- since we know both column have datatype varchar(4), this implies there can be atmost two toppings in a list
---- first can be extracted using LEFT() [ till , - comma is encountered ]
---- second can be extracted by stuffing or removing all character till comma [,]
WITH exclusion_extra_customer_order AS (
	SELECT 
		*,
		CAST(LEFT(exclusions, CHARINDEX(',', exclusions + ',') -1) AS INT) exc1,
		CAST(STUFF(exclusions, 1, LEN(exclusions) +1- CHARINDEX(',', REVERSE(exclusions)), '') AS INT) exc2,
		CAST(LEFT(extras, CHARINDEX(',', extras + ',') -1) AS INT) ext1,
		CAST(STUFF(extras, 1, LEN(extras) +1- CHARINDEX(',', REVERSE(extras)), '') AS INT) ext2
	FROM [pizza_runner].[customer_orders]
),
exclusion_extra_name_customer_order AS (
	SELECT 
		order_id, customer_id, 
		a.pizza_id, exclusions, 
		extras, order_time,
		CASE WHEN exc1 IS NULL THEN '' ELSE exc1 END exc1,
		CASE WHEN exc2 IS NULL THEN '' ELSE exc2 END exc2,
		CASE WHEN ext1 IS NULL THEN '' ELSE ext1 END ext1,
		CASE WHEN ext2 IS NULL THEN '' ELSE ext2 END ext2,
		n.pizza_name,
		tc1.topping_name tc1, 
		tc2.topping_name tc2,
		tx1.topping_name tx1, 
		tx2.topping_name tx2
	FROM exclusion_extra_customer_order a
	LEFT JOIN [pizza_runner].[pizza_names] n on a.pizza_id = n.pizza_id
	LEFT JOIN [pizza_runner].[pizza_toppings] tc1 on a.exc1 = tc1.topping_id
	LEFT JOIN [pizza_runner].[pizza_toppings] tc2 on a.exc2 = tc2.topping_id
	LEFT JOIN [pizza_runner].[pizza_toppings] tx1 on a.ext1 = tx1.topping_id
	LEFT JOIN [pizza_runner].[pizza_toppings] tx2 on a.ext2 = tx2.topping_id
),
exclude_extra_combine_cte AS (
	SELECT 
		order_id, customer_id, pizza_id, exclusions, 
		extras, order_time, pizza_name,
		CASE WHEN tc1 IS NULL THEN ''
			WHEN tc2 IS NULL THEN CONCAT('- Exclude', ' ', tc1)
			ELSE CONCAT('- Exclude', ' ', tc1, ', ', tc2)
			END exc,
		CASE WHEN tx1 IS NULL THEN ''
			WHEN tx2 IS NULL THEN CONCAT('- Extra', ' ', tx1)
			ELSE CONCAT('- Extra', ' ', tx1, ', ', tx2)
			END ext
	FROM exclusion_extra_name_customer_order
)
SELECT 
	order_id, customer_id, pizza_id, exclusions, extras, order_time,
	CONCAT(pizza_name, ' ', exc, ' ', ext) order_item
FROM exclude_extra_combine_cte;
GO








----> 5) Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--		For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

---- order_ingredients() function - upgraded version of getToppings() function
CREATE OR ALTER FUNCTION [pizza_runner].[order_ingredients] (@exclude NVARCHAR(30), @extra NVARCHAR(30), @id INT, @ingredients NVARCHAR(MAX))
RETURNS NVARCHAR(MAX) AS
BEGIN

	SET @exclude = '@' + @exclude + ','
	SET @exclude = REPLACE(@exclude, ' ', '@')
	SET @extra = '@' + @extra + ','
	SET @extra = REPLACE(@extra, ' ', '@')

	IF @id=0
	BEGIN
		DECLARE @excludelist NVARCHAR(300)
		SET @excludelist = ''
	END

	IF @id=1
	BEGIN
		DECLARE @extralist NVARCHAR(300)
		SET @extralist = ''
	END

	--IF @toppings LIKE '\b1(,)' 
	--	SET @list = @list + 'Bacon, '
	
	IF @id = 0 OR @id = 2
	BEGIN
		IF @exclude LIKE '%@1,%' OR @exclude LIKE '%[^0-9]1,%'
			SET @excludelist = @excludelist + 'Bacon, '
		IF @exclude LIKE '%@2,%' OR @exclude LIKE '%[^0-9]2,%'
			SET @excludelist = @excludelist + 'BBQ Sauce, '
		IF @exclude LIKE '%@3,%' OR @exclude LIKE '%[^0-9]3,%'
			SET @excludelist = @excludelist + 'Beef, '
		IF @exclude LIKE '%@4,%' OR @exclude LIKE '%[^0-9]4,%'
			SET @excludelist = @excludelist + 'Cheese, '
		IF @exclude LIKE '%@5,%' OR @exclude LIKE '%[^0-9]5,%'
			SET @excludelist = @excludelist + 'Chicken, '
		IF @exclude LIKE '%@6,%' OR @exclude LIKE '%[^0-9]6,%'
			SET @excludelist = @excludelist + 'Mushrooms, '
		IF @exclude LIKE '%@7,%' OR @exclude LIKE '%[^0-9]7,%'
			SET @excludelist = @excludelist + 'Onions, '
		IF @exclude LIKE '%@8,%' OR @exclude LIKE '%[^0-9]8,%'
			SET @excludelist = @excludelist + 'Pepperoni, '
		IF @exclude LIKE '%@9,%' OR @exclude LIKE '%[^0-9]9,%'
			SET @excludelist = @excludelist + 'Peppers, '
		IF @exclude LIKE '%@10,%' OR @exclude LIKE '%[^0-9]10,%'
			SET @excludelist = @excludelist + 'Salami, '
		IF @exclude LIKE '%@11,%' OR @exclude LIKE '%[^0-9]11,%'
			SET @excludelist = @excludelist + 'Tomatoes, '
		IF @exclude LIKE '%@12,%' OR @exclude LIKE '%[^0-9]12,%'
			SET @excludelist = @excludelist + 'Tomato Sauce, '
	END

	IF @id = 1 OR @id = 2
	BEGIN
		IF @extra LIKE '%@1,%' OR @extra LIKE '%[^0-9]1,%'
			SET @extralist = @extralist + 'Bacon, '
		IF @extra LIKE '%@2,%' OR @extra LIKE '%[^0-9]2,%'
			SET @extralist = @extralist + 'BBQ Sauce, '
		IF @extra LIKE '%@3,%' OR @extra LIKE '%[^0-9]3,%'
			SET @extralist = @extralist + 'Beef, '
		IF @extra LIKE '%@4,%' OR @extra LIKE '%[^0-9]4,%'
			SET @extralist = @extralist + 'Cheese, '
		IF @extra LIKE '%@5,%' OR @extra LIKE '%[^0-9]5,%'
			SET @extralist = @extralist + 'Chicken, '
		IF @extra LIKE '%@6,%' OR @extra LIKE '%[^0-9]6,%'
			SET @extralist = @extralist + 'Mushrooms, '
		IF @extra LIKE '%@7,%' OR @extra LIKE '%[^0-9]7,%'
			SET @extralist = @extralist + 'Onions, '
		IF @extra LIKE '%@8,%' OR @extra LIKE '%[^0-9]8,%'
			SET @extralist = @extralist + 'Pepperoni, '
		IF @extra LIKE '%@9,%' OR @extra LIKE '%[^0-9]9,%'
			SET @extralist = @extralist + 'Peppers, '
		IF @extra LIKE '%@10,%' OR @extra LIKE '%[^0-9]10,%'
			SET @extralist = @extralist + 'Salami, '
		IF @extra LIKE '%@11,%' OR @extra LIKE '%[^0-9]11,%'
			SET @extralist = @extralist + 'Tomatoes, '
		IF @extra LIKE '%@12,%' OR @extra LIKE '%[^0-9]12,%'
			SET @extralist = @extralist + 'Tomato Sauce, '
	END
	--RAISERROR(@list, 0, 1)


	IF @ingredients IS NOT NULL
	BEGIN
		IF @id = 0 OR @id = 2
		BEGIN
			IF PATINDEX('%Bacon%', @excludelist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Bacon, ', '')
			IF PATINDEX('%BBQ Sauce%', @excludelist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'BBQ Sauce, ', '')
			IF PATINDEX('%Beef%', @excludelist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Beef, ', '')
			IF PATINDEX('%Cheese%', @excludelist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Cheese, ', '')
			IF PATINDEX('%Chicken%', @excludelist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Chicken, ', '')
			IF PATINDEX('%Mushrooms%', @excludelist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Mushrooms, ', '')
			IF PATINDEX('%Onions%', @excludelist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Onions, ', '')
			IF PATINDEX('%Pepperoni%', @excludelist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Pepperoni, ', '')
			IF PATINDEX('%Peppers%', @excludelist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Peppers, ', '')
			IF PATINDEX('%Salami%', @excludelist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Salami, ', '')
			IF PATINDEX('%Tomatoes%', @excludelist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Tomatoes, ', '')
			IF PATINDEX('%Tomato Sauce%', @excludelist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Tomato Sauce', '')
		END

		IF @id = 1 OR @id = 2
		BEGIN
			IF PATINDEX('%Bacon%', @extralist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Bacon', '2xBacon')
			IF PATINDEX('%BBQ Sauce%', @extralist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'BBQ Sauce', '2xBBQ Sauce')
			IF PATINDEX('%Beef%', @extralist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Beef', '2xBeef')
			IF PATINDEX('%Cheese%', @extralist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Cheese', '2xCheese')
			IF PATINDEX('%Chicken%', @extralist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Chicken', '2xChicken')
			IF PATINDEX('%Mushrooms%', @extralist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Mushrooms', '2xMushrooms')
			IF PATINDEX('%Onions%', @extralist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Onions', '2xOnions')
			IF PATINDEX('%Pepperoni%', @extralist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Pepperoni', '2xPepperoni')
			IF PATINDEX('%Peppers%', @extralist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Peppers', '2xPeppers')
			IF PATINDEX('%Salami%', @extralist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Salami', '2xSalami')
			IF PATINDEX('%Tomatoes%', @extralist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Tomatoes', '2xTomatoes')
			IF PATINDEX('%Tomato Sauce%', @extralist) <> 0
				SET @ingredients = REPLACE(@ingredients, 'Tomato Sauce', '2xTomato Sauce')
		END

		RETURN @ingredients
	END
	
	RETURN LEFT(COALESCE(@excludelist, @extralist), LEN(COALESCE(@excludelist, @extralist)) - 1)
END;
GO

WITH ingredients_cte AS (
	SELECT pizza_name,
		pizza_name + ': ' + STRING_AGG(topping_name, ', ') AS "ingredients"
	FROM [pizza_runner].[pizza_names] pn
	JOIN [pizza_runner].[pizza_recipe_view] prv
		ON pn.pizza_id = prv.pizza_id
	JOIN [pizza_runner].[pizza_toppings] pt
		ON prv.topping_id = pt.topping_id
	GROUP BY pizza_name
)
SELECT co.*, 
	CASE
		WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN [pizza_runner].[order_ingredients](exclusions, extras, 2, ingredients)
		WHEN exclusions IS NOT NULL THEN [pizza_runner].[order_ingredients](exclusions, NULL, 0, ingredients)
		WHEN extras IS NOT NULL THEN [pizza_runner].[order_ingredients](NULL, extras, 1, ingredients)
		ELSE ingredients
	END AS "pizza_order_detail"
FROM [pizza_runner].[customer_orders] co
JOIN [pizza_runner].[pizza_names] pn
	ON co.pizza_id = pn.pizza_id
JOIN ingredients_cte ing
	ON pn.pizza_name = ing.pizza_name;
GO







---> 6) What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

WITH total_topping_count_cte AS (
	SELECT
		topping_id,
		COUNT(*) AS "total"
	FROM [pizza_runner].[customer_orders] co
	JOIN [pizza_runner].[runner_orders] ro
		ON co.order_id = ro.order_id
	JOIN [pizza_runner].[pizza_recipe_view] prv
		ON co.pizza_id = prv.pizza_id
	WHERE cancellation IS NULL
	GROUP BY topping_id
),
exclusion_topping_count_cte AS (
	SELECT
		exclusion AS "topping_id",
		-COUNT(exclusion) AS "total"
	FROM (
		SELECT CAST(TRIM(value) AS INT) AS "exclusion"
		FROM [pizza_runner].[customer_orders] co
		JOIN [pizza_runner].[runner_orders] ro
			ON co.order_id = ro.order_id
		CROSS APPLY STRING_SPLIT(exclusions, ',')
		WHERE cancellation IS NULL
	) co
	GROUP BY exclusion
),
extra_topping_count_cte AS(
	SELECT
		extra AS "topping_id",
		COUNT(extra) AS "total"
	FROM (
		SELECT CAST(TRIM(value) AS INT) AS "extra"
		FROM [pizza_runner].[customer_orders] co
		JOIN [pizza_runner].[runner_orders] ro
			ON co.order_id = ro.order_id
		CROSS APPLY STRING_SPLIT(extras, ',')
		WHERE cancellation IS NULL
	) co
	GROUP BY extra
)
SELECT 
	topping_name,
	a.topping_id,
	SUM(total) AS total
FROM (
	SELECT * FROM total_topping_count_cte
	UNION ALL
	SELECT * FROM exclusion_topping_count_cte
	UNION ALL
	SELECT * FROM extra_topping_count_cte		
) a
JOIN [pizza_runner].[pizza_toppings] pt
	ON a.topping_id = pt.topping_id
GROUP BY topping_name, a.topping_id
ORDER BY total DESC;
GO


















---------------------------------------------------------------------------------------------> D. Pricing and Ratings <---------------------------------------------------------------------------------------------
---> 1) If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT 
	runner_id,
	SUM(
		CASE 
			WHEN pizza_name = 'Meatlovers' THEN 12
			ELSE 10
		END
	) AS "money_made"
FROM [pizza_runner].[runner_orders] ro
JOIN [pizza_runner].[customer_orders] co
	ON ro.order_id = co.order_id
JOIN [pizza_runner].[pizza_names] pn
	ON co.pizza_id = pn.pizza_id
WHERE cancellation IS NULL
GROUP BY runner_id
GO



---> 2) What if there was an additional $1 charge for any pizza extras?
--			Add cheese is $1 extra


---- view for customer_order table for same order more than once (example: order_id=4)
CREATE VIEW [pizza_runner].[customer_similar_orders_view] 
AS
	SELECT *, COUNT(*) "similar_pizza_order_count"
	FROM [pizza_runner].[customer_orders]
	GROUP BY order_id, customer_id, pizza_id, exclusions, extras, order_time
GO


---- view for customer_order table with unique row number
CREATE OR ALTER VIEW [pizza_runner].[customer_orders_row_wise_view] 
AS
	SELECT *, ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS "row_no"
	FROM [pizza_runner].[customer_orders]
GO



-- using group by in view for similar order by a customer -- relative cost 48%
WITH pizza_order_cte AS (
	SELECT 
		co.order_id, 
		customer_id,
		runner_id,
		co.pizza_id, 
		exclusions, 
		extras, 
		similar_pizza_order_count, 
		count(value) AS "total_extras",
		(
			CASE 
				WHEN pizza_name = 'Meatlovers' THEN similar_pizza_order_count*(12 + count(value)*1)
				ELSE 10 + count(value)*1
			END
		) AS "pizza_price"
	FROM [pizza_runner].[customer_similar_orders_view] co
	JOIN [pizza_runner].[runner_orders] ro
		ON co.order_id = ro.order_id
	JOIN [pizza_runner].[pizza_names] pn
		ON co.pizza_id = pn.pizza_id
	OUTER APPLY STRING_SPLIT(extras, ',')
	WHERE cancellation IS NULL
	GROUP BY co.order_id, customer_id, runner_id, co.pizza_id, pizza_name, exclusions, extras, similar_pizza_order_count
)
SELECT runner_id, SUM(pizza_price) AS "runner_amount"
FROM pizza_order_cte
GROUP BY runner_id
GO


-- more cost effective - using row number in view -- relative cost 37%
WITH pizza_order_cte AS (
	SELECT 
		co.order_id, 
		customer_id,
		runner_id,
		co.pizza_id, 
		exclusions, 
		extras, 
		row_no, 
		count(value) AS "total_extras",
		(
			CASE 
				WHEN pizza_name = 'Meatlovers' THEN 12 + count(value)*1
				ELSE 10 + count(value)*1
			END
		) AS "pizza_price"
	FROM [pizza_runner].[customer_orders_row_wise_view] co
	JOIN [pizza_runner].[runner_orders] ro
		ON co.order_id = ro.order_id
	JOIN [pizza_runner].[pizza_names] pn
		ON co.pizza_id = pn.pizza_id
	OUTER APPLY STRING_SPLIT(extras, ',')
	WHERE cancellation IS NULL
	GROUP BY co.order_id, customer_id, runner_id, co.pizza_id, pizza_name, exclusions, extras, row_no
)
SELECT runner_id, SUM(pizza_price) AS "runner_amount"
FROM pizza_order_cte
GROUP BY runner_id
GO


-- shortcut method -- relative cost 16%
-- if we check schema then we can see that extra can atmost have 4 characters only so maximum extra toppings will be 2 and minimum 1... 
-- so if length of extras is less than or equal 2 then we will only have one extra toppings (total charge = pizza_price + 1$ extra) and more than 2 then 2 toppings (total charge = pizza_price + 2$ extra)
SELECT 
	runner_id,
	SUM(
		CASE 
			WHEN pizza_name = 'Meatlovers' THEN
				CASE 
					WHEN extras IS NULL THEN 12
					WHEN LEN(extras) < 3 THEN 13
					ELSE 14
				END
			WHEN pizza_name = 'Vegetarian' THEN
				CASE 
					WHEN extras IS NULL THEN 10
					WHEN LEN(extras) < 3 THEN 11
					ELSE 12
				END
		END
	) AS "money_made"
FROM [pizza_runner].[runner_orders] ro
JOIN [pizza_runner].[customer_orders] co
	ON ro.order_id = co.order_id
JOIN [pizza_runner].[pizza_names] pn
	ON co.pizza_id = pn.pizza_id
WHERE cancellation IS NULL
GROUP BY runner_id
GO






---> 3) The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema 
--->	for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
CREATE SCHEMA pizza_runner_rating;
GO

SELECT *
INTO pizza_runner_rating.runner_orders
FROM [pizza_runner].[runner_orders];
GO

ALTER TABLE [pizza_runner_rating].[runner_orders]
ADD ratings INT;

SELECT * FROM [pizza_runner_rating].[runner_orders];

DECLARE @counter INT;
SET @counter = 0;

WHILE @counter<10
BEGIN
	SET @counter = @counter+1

	IF @counter IN (6, 9) 
		CONTINUE;
		
	UPDATE [pizza_runner_rating].[runner_orders]
	SET ratings = FLOOR(RAND() * (5 - 1 + 1)) + 1
	WHERE order_id = @counter;
END

GO




---> 4) Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
--			customer_id
--			order_id
--			runner_id
--			rating
--			order_time
--			pickup_time
--			Time between order and pickup
--			Delivery duration
--			Average speed
--			Total number of pizzas

-- considering delivery duration as time taken by runner after picking up order
SELECT 
	customer_id,
	co.order_id,
	runner_id,
	ratings,
	order_time,
	pickup_time,
	ROUND(CAST(DATEDIFF(SECOND, order_time, pickup_time) AS REAL)/60, 2) AS "pickup_duration (min)",
	duration AS "delivery_duration (min)",
	ROUND(AVG(distance/(duration/60.0)), 2) AS "avg_speed (kmph)",
	COUNT(*) AS "total_pizza_ordered"
FROM [pizza_runner].[customer_orders] co
JOIN [pizza_runner_rating].[runner_orders] ro
	ON co.order_id = ro.order_id
WHERE cancellation IS NULL
GROUP BY customer_id, co.order_id, runner_id, ratings, order_time, pickup_time, duration
ORDER BY co.order_id;
GO

-- considering delivery duration = duration + pickup_duration
SELECT 
	customer_id,
	co.order_id,
	runner_id,
	ratings,
	order_time,
	pickup_time,
	ROUND(CAST(DATEDIFF(SECOND, order_time, pickup_time) AS REAL)/60, 2) AS "pickup_duration (min)",
	duration + ROUND(CAST(DATEDIFF(SECOND, order_time, pickup_time) AS REAL)/60, 2) AS "delivery_duration (min)",
	ROUND(AVG(distance/((duration + CAST(DATEDIFF(SECOND, order_time, pickup_time) AS REAL)/60) / 60)), 2) AS "avg_speed (kmph)",
	COUNT(*) AS "total_pizza_ordered"
FROM [pizza_runner].[customer_orders] co
JOIN [pizza_runner_rating].[runner_orders] ro
	ON co.order_id = ro.order_id
WHERE cancellation IS NULL
GROUP BY customer_id, co.order_id, runner_id, ratings, order_time, pickup_time, duration
ORDER BY co.order_id;
GO





--5) If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
SELECT 
	runner_id,
	ROUND(SUM(
		CASE 
			WHEN pizza_name = 'Meatlovers' THEN 12
			ELSE 10
		END
	), 2) AS "pizza_cost",
	ROUND( SUM(0.3*distance), 2) AS "expenses",
	ROUND(SUM(
		CASE 
			WHEN pizza_name = 'Meatlovers' THEN 12 - 0.3*distance
			ELSE 10 - 0.3*distance
		END
	), 2) AS "money_made"
FROM [pizza_runner].[runner_orders] ro
JOIN [pizza_runner].[customer_orders] co
	ON ro.order_id = co.order_id
JOIN [pizza_runner].[pizza_names] pn
	ON co.pizza_id = pn.pizza_id
WHERE cancellation IS NULL
GROUP BY runner_id;
GO


















---------------------------------------------------------------------------------------------> E. Bonus Questions <---------------------------------------------------------------------------------------------
---> If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was 
---> added to the Pizza Runner menu?


-- Ans. we need to add pizza name in pizza_names table and recipe in pizza_recipes table
INSERT INTO [pizza_runner].[pizza_names]
VALUES (3, 'Supreme');

INSERT INTO [pizza_runner].[pizza_recipes]
VALUES (3, (SELECT STRING_AGG(topping_id, ', ') FROM [pizza_runner].[pizza_toppings]));
GO

SELECT * FROM [pizza_runner].[pizza_names];
SELECT * FROM [pizza_runner].[pizza_recipes];
GO