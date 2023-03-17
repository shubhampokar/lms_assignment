CREATE SCHEMA dannys_diner;
GO


CREATE TABLE dannys_diner.sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO dannys_diner.sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
GO


CREATE TABLE dannys_diner.menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO dannys_diner.menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
GO


CREATE TABLE dannys_diner.members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO dannys_diner.members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
GO


















---> 1) What is the total amount each customer spent at the restaurant?
SELECT 
	customer_id, 
	SUM(price) AS "total_spent"
FROM [dannys_diner].[sales] s
JOIN [dannys_diner].[menu] m
	ON s.product_id = m.product_id
GROUP BY customer_id;
GO





---> 2) How many days has each customer visited the restaurant?
SELECT 
	customer_id, 
	COUNT(DISTINCT order_date) AS "total_days_visited"
FROM [dannys_diner].[sales] s
JOIN [dannys_diner].[menu] m
	ON s.product_id = m.product_id
GROUP BY customer_id;
GO





---> 3) What was the first item from the menu purchased by each customer?

-- Solution if product mentioned are in order according to datetime
WITH purchase_no_cte AS (
	SELECT 
		customer_id, 
		order_date, 
		product_name,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) "order_no"
	FROM [dannys_diner].[sales] s
	JOIN [dannys_diner].[menu] m
		ON s.product_id = m.product_id

)
SELECT customer_id, product_name AS "first_item_ordered"
FROM purchase_no_cte
WHERE order_no = 1;
GO


-- Solution if product mentioned are in order according to date, i.e. order was given at same time on given date
WITH purchase_no_cte AS (
	SELECT 
		DISTINCT customer_id, 
		order_date, 
		product_name,
		RANK() OVER(PARTITION BY customer_id ORDER BY order_date) "order_no"
	FROM [dannys_diner].[sales] s
	JOIN [dannys_diner].[menu] m
		ON s.product_id = m.product_id
)
SELECT 
	customer_id,  
	STRING_AGG(product_name, ', ') AS "first_item_ordered"
FROM purchase_no_cte
WHERE order_no = 1
GROUP BY customer_id;
GO






---> 4) What is the most purchased item on the menu and how many times was it purchased by all customers?

-- most purchased item = ramen
SELECT TOP 1 
	s.product_id,
	product_name
FROM [dannys_diner].[sales] s
JOIN [dannys_diner].[menu] m
	ON s.product_id = m.product_id
GROUP BY s.product_id, product_name
ORDER BY COUNT(customer_id) DESC


-- total no. of times each customer bought overall most bought item
SELECT 
	customer_id, 
	product_name AS "most_purchased_item", 
	COUNT(*) AS "order_count"
FROM [dannys_diner].[sales] s
JOIN [dannys_diner].[menu] m
	ON s.product_id = m.product_id
WHERE s.product_id = (
						SELECT TOP 1 
							s.product_id
						FROM [dannys_diner].[sales] s
						JOIN [dannys_diner].[menu] m
							ON s.product_id = m.product_id
						GROUP BY s.product_id
						ORDER BY COUNT(customer_id) DESC
					)
GROUP BY customer_id, product_name;
GO





---> 5) Which item was the most popular for each customer?
WITH most_popular_cte AS (
	SELECT 
		customer_id, 
		product_name, 
		COUNT(*) AS "order_count",
		RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(*) DESC) "rank_no"
	FROM [dannys_diner].[sales] s
	JOIN [dannys_diner].[menu] m
		ON s.product_id = m.product_id
	GROUP BY customer_id, product_name
)
SELECT customer_id, STRING_AGG(product_name, ',') AS "most_popular_item" 
FROM most_popular_cte
WHERE rank_no = 1
GROUP BY customer_id;
GO





---> 6) Which item was purchased first by the customer after they became a member?

-- considering customer bought any item only after becoming member for join_date, therefore join_date is considered in calculation
-- Solution if product mentioned are in order according to datetime ------ therefore row_number() is used
WITH purchase_no_cte AS (
	SELECT 
		m.customer_id, 
		product_name,
		ROW_NUMBER() OVER(PARTITION BY m.customer_id ORDER BY order_date) "order_no"
	FROM [dannys_diner].[members] m
	JOIN [dannys_diner].[sales] s
		ON m.customer_id = s.customer_id
	JOIN [dannys_diner].[menu] n
		ON s.product_id = n.product_id
	WHERE order_date >= join_date
)
SELECT customer_id, product_name AS "first_item_ordered"
FROM purchase_no_cte 
WHERE order_no = 1;
GO


-- Solution if product mentioned are in order according to date ------ therefore rank() is used
WITH purchase_no_cte AS (
	SELECT 
		m.customer_id, 
		product_name,
		RANK() OVER(PARTITION BY m.customer_id ORDER BY order_date) "order_no"
	FROM [dannys_diner].[members] m
	JOIN [dannys_diner].[sales] s
		ON m.customer_id = s.customer_id
	JOIN [dannys_diner].[menu] n
		ON s.product_id = n.product_id
	WHERE order_date >= join_date
)
SELECT 
	customer_id,  
	STRING_AGG(product_name, ', ') AS "first_item_ordered"
FROM purchase_no_cte
WHERE order_no = 1
GROUP BY customer_id;
GO






---> 7) Which item was purchased just before the customer became a member?

-- Solution if product mentioned are in order according to datetime ------ therefore row_number() is used
WITH purchase_no_cte AS (
	SELECT 
		m.customer_id,
		product_name,
		ROW_NUMBER() OVER(PARTITION BY m.customer_id ORDER BY order_date DESC) "order_no"
	FROM [dannys_diner].[members] m
	JOIN [dannys_diner].[sales] s
		ON m.customer_id = s.customer_id
	JOIN [dannys_diner].[menu] n
		ON s.product_id = n.product_id
	WHERE order_date < join_date
)
SELECT customer_id, product_name AS "first_item_ordered"
FROM purchase_no_cte 
WHERE order_no = 1;
GO


-- Solution if product mentioned are in order according to date ------ therefore rank() is used
WITH purchase_no_cte AS (
	SELECT 
		m.customer_id, 
		product_name,
		RANK() OVER(PARTITION BY m.customer_id ORDER BY order_date) "order_no"
	FROM [dannys_diner].[members] m
	JOIN [dannys_diner].[sales] s
		ON m.customer_id = s.customer_id
	JOIN [dannys_diner].[menu] n
		ON s.product_id = n.product_id
	WHERE order_date < join_date
)
SELECT 
	customer_id,  
	STRING_AGG(product_name, ', ') AS "first_item_ordered"
FROM purchase_no_cte
WHERE order_no = 1
GROUP BY customer_id;
GO






---> 8) What is the total items and amount spent for each member before they became a member?
SELECT 
	m.customer_id, 
	COUNT(DISTINCT s.product_id) AS "total_items", 
	SUM(price) AS "total_amount_spent"
FROM [dannys_diner].[members] m
JOIN [dannys_diner].[sales] s
	ON m.customer_id = s.customer_id
JOIN [dannys_diner].[menu] n
	ON s.product_id = n.product_id
WHERE order_date < join_date
GROUP BY m.customer_id;
GO







---> 9) If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH point_cte AS(
	SELECT 
		s.customer_id,
		CASE 
			WHEN s.product_id = 1 THEN price*20
			ELSE price*10
		END AS "points"
	FROM [dannys_diner].[sales] s
	JOIN [dannys_diner].[menu] m
		ON s.product_id = m.product_id
)
SELECT 
	customer_id, 
	SUM(points) AS "total_points"
FROM point_cte
GROUP BY customer_id;
GO







---> 10) In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH point_cte AS(
	SELECT s.customer_id, 
		--CASE 
		--	WHEN (order_date>=join_date AND DATEDIFF(DAY, join_date, order_date)<7) THEN CAST(DATEDIFF(DAY, join_date, order_date) AS VARCHAR)
		--	ELSE 'false'
		--END,
		CASE 
			WHEN (s.product_id = 1) OR (order_date>=join_date AND DATEDIFF(DAY, join_date, order_date)<7) THEN price*20
			ELSE price*10
		END AS "points"
	FROM [dannys_diner].[members] m
	JOIN [dannys_diner].[sales] s
		ON m.customer_id = s.customer_id
	JOIN [dannys_diner].[menu] n
		ON s.product_id = n.product_id
	WHERE order_date < '2021-01-31'
)
SELECT 
	customer_id, 
	SUM(points) AS "total_points"
FROM point_cte
GROUP BY customer_id;
GO



















---------------------------------------------------------------------------------------------> Bonus Questions <--------------------------------------------------------------------------------------------- 

---> JOIN ALL THE THINGS

----The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.
----Recreate the following table output using the available data:

----	customer_id		order_date		product_name		price		member

----		A			2021-01-01			curry			15			N
----		A			2021-01-01			sushi			10			N
----		A			2021-01-07			curry			15			Y
----		A			2021-01-10			ramen			12			Y
----		A			2021-01-11			ramen			12			Y
----		A			2021-01-11			ramen			12			Y
----		B			2021-01-01			curry			15			N
----		B			2021-01-02			curry			15			N
----		B			2021-01-04			sushi			10			N
----		B			2021-01-11			sushi			10			Y
----		B			2021-01-16			ramen			12			Y
----		B			2021-02-01			ramen			12			Y
----		C			2021-01-01			ramen			12			N
----		C			2021-01-01			ramen			12			N
----		C			2021-01-07			ramen			12			N


WITH join_cte AS (
	SELECT s.customer_id, join_date, order_date, product_name, price, m.customer_id "member"
		FROM [dannys_diner].[sales] s
	LEFT JOIN [dannys_diner].[members] m
		ON m.customer_id = s.customer_id
	JOIN [dannys_diner].[menu] n
		ON s.product_id = n.product_id
)
SELECT customer_id, order_date, product_name, price,
	CASE 
		WHEN (member IS NULL OR join_date>order_date) THEN 'N'
		ELSE 'Y'
	END AS "member"
INTO dannys_diner.all_data_in_one
FROM join_cte;
GO







---> RANKING ALL THE THINGS

----Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects 
----null ranking values for the records when customers are not yet part of the loyalty program.

----	customer_id		order_date		product_name		price		member		ranking

----		A			2021-01-01			curry			15			N			NULL
----		A			2021-01-01			sushi			10			N			NULL
----		A			2021-01-07			curry			15			Y			1
----		A			2021-01-10			ramen			12			Y			2
----		A			2021-01-11			ramen			12			Y			3
----		A			2021-01-11			ramen			12			Y			3
----		B			2021-01-01			curry			15			N			NULL
----		B			2021-01-02			curry			15			N			NULL
----		B			2021-01-04			sushi			10			N			NULL
----		B			2021-01-11			sushi			10			Y			1
----		B			2021-01-16			ramen			12			Y			2
----		B			2021-02-01			ramen			12			Y			3
----		C			2021-01-01			ramen			12			N			NULL
----		C			2021-01-01			ramen			12			N			NULL
----		C			2021-01-07			ramen			12			N			NULL

SELECT 
	*,
	CASE
		WHEN member='N' THEN NULL
		ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
	END AS "rank"
FROM [dannys_diner].[all_data_in_one];
GO