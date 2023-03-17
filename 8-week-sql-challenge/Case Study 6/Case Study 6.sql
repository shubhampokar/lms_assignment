---------------------------------------------------------------------------------------------> 1. Enterprise Relationship Diagram <---------------------------------------------------------------------------------------------
--Using the following DDL schema details to create an ERD for all the Clique Bait datasets.

Table "clique_bait"."event_identifier" {
  "event_type" INTEGER
  "event_name" VARCHAR(13)
}

Table "clique_bait"."campaign_identifier" {
  "campaign_id" INTEGER
  "products" VARCHAR(3)
  "campaign_name" VARCHAR(33)
  "start_date" timestamp
  "end_date" timestamp
}

Table "clique_bait"."page_hierarchy" {
  "page_id" INTEGER
  "page_name" VARCHAR(14)
  "product_category" VARCHAR(9)
  "product_id" INTEGER
}

Table "clique_bait"."users" {
  "user_id" INTEGER
  "cookie_id" VARCHAR(6)
  "start_date" timestamp
}

Table "clique_bait"."events" {
  "visit_id" VARCHAR(6)
  "cookie_id" VARCHAR(6)
  "page_id" INTEGER
  "event_type" INTEGER
  "sequence_number" INTEGER
  "event_time" timestamp
}



Ref: "clique_bait"."event_identifier"."event_type" < "clique_bait"."events"."event_type"

Ref: "clique_bait"."page_hierarchy"."page_id" < "clique_bait"."events"."page_id"

Ref: "clique_bait"."users"."cookie_id" < "clique_bait"."events"."cookie_id"



















---------------------------------------------------------------------------------------------> 2. Digital Analysis <---------------------------------------------------------------------------------------------
--- Using the available datasets - answer the following questions using a single query for each one:

---> 1) How many users are there?
SELECT
	COUNT(DISTINCT [user_id]) AS "total_user"
FROM [clique_bait].[users];
GO




---> 2) How many cookies does each user have on average?

-- rounded to decimal 0 as cookies can't be in fraction
SELECT
	ROUND(
		COUNT(cookie_id)/CAST(COUNT(DISTINCT [user_id]) AS REAL), 
		0
	) AS "avg_cookies_per_user"
FROM [clique_bait].[users];
GO




---> 3) What is the unique number of visits by all users per month?

-- unique visits per month by all users, i.e. - avg visit by each user per month
SELECT
	[user_id], 
	CAST(COUNT(DISTINCT visit_id) AS REAL) / (SELECT COUNT(DISTINCT MONTH(event_time)) FROM [clique_bait].[events]) AS "avg_visits_per_month"
FROM [clique_bait].[events] e
JOIN [clique_bait].[users] u
	ON e.cookie_id = u.cookie_id
GROUP BY [user_id]
ORDER BY [user_id];
GO


-- unique visits by all users per month, i.e. - total unique visits by each user per month
SELECT
	DATENAME(MONTH, event_time) AS "month", 
	[user_id],
	COUNT(DISTINCT visit_id) AS "visits_per_month"
FROM [clique_bait].[events] e
JOIN [clique_bait].[users] u
	ON e.cookie_id = u.cookie_id
GROUP BY DATENAME(MONTH, event_time), [user_id]
ORDER BY DATENAME(MONTH, event_time), [user_id];
GO


-- unique visits per month, i.e. - total unique visits per month
SELECT
	DATENAME(MONTH, event_time) AS "month", 
	COUNT(DISTINCT visit_id) AS "visits_per_month"
FROM [clique_bait].[events] e
JOIN [clique_bait].[users] u
	ON e.cookie_id = u.cookie_id
GROUP BY DATENAME(MONTH, event_time)
ORDER BY DATENAME(MONTH, event_time);
GO





---> 4) What is the number of events for each event type?
SELECT
	event_name,
	COUNT(event_name) AS "event_count"
FROM [clique_bait].[events] e
JOIN [clique_bait].[event_identifier] ei
	ON e.event_type = ei.event_type
GROUP BY event_name;
GO




---> 5) What is the percentage of visits which have a purchase event?
SELECT
	ROUND(
		(
			(
				SELECT CAST(COUNT(DISTINCT visit_id) AS REAL) FROM [clique_bait].[events] WHERE event_type=3
			) / COUNT(DISTINCT visit_id)
		) * 100,
		2
	) AS "purchase_event (%)"
FROM [clique_bait].[events];
GO




---> 6) What is the percentage of visits which view the checkout page but do not have a purchase event?

-- checking if there is unique combination of visit and cookie -- true
SELECT 
	visit_id, cookie_id, COUNT(*)
FROM [clique_bait].[events] e
JOIN [clique_bait].[event_identifier] ei
	ON e.event_type = ei.event_type
JOIN [clique_bait].[page_hierarchy] ph
	ON e.page_id = ph.page_id
WHERE sequence_number=1
GROUP BY visit_id, cookie_id
HAVING COUNT(*)>1;
GO

-- method 1 -- relative cost: 51%
WITH checkout_without_purchase_cte AS (
	SELECT
		visit_id, 
		cookie_id,
		SUM(
			CASE
				WHEN page_name = 'Checkout' THEN 1
				WHEN event_name = 'Purchase' THEN -1
			END
		) AS "checkout_without_purchase_flag"
	FROM [clique_bait].[events] e
	JOIN [clique_bait].[event_identifier] ei
		ON e.event_type = ei.event_type
	JOIN [clique_bait].[page_hierarchy] ph
		ON e.page_id = ph.page_id
	WHERE page_name = 'Checkout' OR event_name = 'Purchase'
	GROUP BY visit_id, cookie_id
)
SELECT 
	--ROUND(
	--	(
	--		COUNT(
	--			CASE 
	--				WHEN checkout_without_purchase_flag = 1 THEN 1
	--				ELSE NULL
	--			END
	--		) / CAST(COUNT(visit_id) AS REAL)
	--	) * 100,
	--	2
	--) AS "checkout_without_purchase (%)",
	ROUND(
		(
			SUM(checkout_without_purchase_flag) / CAST(COUNT(visit_id) AS REAL)
		) * 100,
		2
	)AS "checkout_without_purchase (%)"
FROM checkout_without_purchase_cte;
GO


-- method 2 -- relative cost: 49%
SELECT TOP 1
	ROUND(
		(
			CAST(
				COUNT(
					CASE
						WHEN COUNT(sequence_number) = 1 THEN 1
						ELSE NULL
					END
				) OVER() AS REAL
			) / COUNT(
				CASE
					WHEN COUNT(sequence_number) > 0 THEN 1
					ELSE NULL
				END
			) OVER()
		) * 100,
		2
	) AS "checkout_without_purchase (%)"
FROM [clique_bait].[events] e
JOIN [clique_bait].[event_identifier] ei
	ON e.event_type = ei.event_type
JOIN [clique_bait].[page_hierarchy] ph
	ON e.page_id = ph.page_id
WHERE page_name = 'Checkout' OR event_name = 'Purchase'
GROUP BY visit_id, cookie_id;
GO





---> 7) What are the top 3 pages by number of views?
SELECT TOP 3
	page_name,
	COUNT(visit_id) AS "total_page_views"
FROM [clique_bait].[events] e
JOIN [clique_bait].[page_hierarchy] ph
	ON e.page_id = ph.page_id
JOIN [clique_bait].[event_identifier] ei
	ON e.event_type = ei.event_type
WHERE event_name='Page View'
GROUP BY page_name
ORDER BY total_page_views DESC;
GO




---> 8) What is the number of views and cart adds for each product category?
SELECT 
	product_category,
	SUM(
		CASE 
			WHEN event_name = 'Page View' THEN 1
			ELSE 0
		END
	) "total_page_views",
	SUM(
		CASE 
			WHEN event_name = 'Add to Cart' THEN 1
			ELSE 0
		END
	) AS "total_add_to_cart_event"
FROM [clique_bait].[events] e
JOIN [clique_bait].[event_identifier] ei
	ON e.event_type = ei.event_type
JOIN [clique_bait].[page_hierarchy] ph
	ON e.page_id = ph.page_id
WHERE product_id IS NOT NULL AND event_name IN ('Page View', 'Add to Cart')
GROUP BY product_category;
GO




---> 9) What are the top 3 products by purchases?
-- method 1 -- relative cost: 34%
WITH purchase_cte AS (
	SELECT
		visit_id,
		cookie_id,
		SUM(
			CASE
				WHEN page_name='Salmon' THEN 1
			END
		) AS "salmon",
		SUM(
			CASE
				WHEN page_name='Kingfish' THEN 1
			END
		) AS "kingfish",
		SUM(
			CASE
				WHEN page_name='Tuna' THEN 1
			END
		) AS "tuna",
		SUM(
			CASE
				WHEN page_name='Russian Caviar' THEN 1
			END
		) AS "russian_caviar",
		SUM(
			CASE
				WHEN page_name='Black Truffle' THEN 1
			END
		) AS "black_truffle",
		SUM(
			CASE
				WHEN page_name='Abalone' THEN 1
			END
		) AS "abalone",
		SUM(
			CASE
				WHEN page_name='Lobster' THEN 1
			END
		) AS "lobster",
		SUM(
			CASE
				WHEN page_name='Crab' THEN 1 
			END
		)  AS "crab",
		SUM(
			CASE
				WHEN page_name='Oyster' THEN 1 
			END
		)  AS "oyster",
		SUM(
			CASE
				WHEN event_name='Purchase' THEN 1
			END
		) AS "purchase"
	FROM [clique_bait].[events] e
	JOIN [clique_bait].[event_identifier] ei
		ON e.event_type = ei.event_type
	JOIN [clique_bait].[page_hierarchy] ph
		ON e.page_id = ph.page_id
	WHERE 
		(
			product_id IS NOT NULL 
			AND 
			event_name = 'Add to Cart'
		)
		OR
		event_name='Purchase'
	GROUP BY visit_id, cookie_id
)
SELECT TOP 3
	product_name, total_purchases
FROM (
	SELECT
		'count' AS total,
		COUNT(salmon) AS "salmon",
		COUNT(kingfish) AS "kingfish",
		COUNT(tuna) AS "tuna",
		COUNT(russian_caviar) AS "russian_caviar",
		COUNT(black_truffle) AS "black_truffle",
		COUNT(abalone) AS "abalone",
		COUNT(lobster) AS "lobster",
		COUNT(crab) AS "crab",
		COUNT(oyster) AS "oyster"
	FROM purchase_cte
	WHERE purchase IS NOT NULL
) tb
UNPIVOT
(
	total_purchases FOR product_name IN ("salmon", "kingfish", "tuna", "russian_caviar", "black_truffle", "abalone", "lobster", "crab", "oyster")
) upvt
ORDER BY total_purchases DESC;
GO


-- method 2 -- relative cost: 66%
WITH purchase_cte AS (
	SELECT
		visit_id,
		cookie_id,
		page_name,
		SUM(
			CASE
				WHEN event_name='Purchase' THEN 1
			END
		) AS "purchase"
	FROM [clique_bait].[events] e
	JOIN [clique_bait].[event_identifier] ei
		ON e.event_type = ei.event_type
	JOIN [clique_bait].[page_hierarchy] ph
		ON e.page_id = ph.page_id
	WHERE 
		(
			product_id IS NOT NULL 
			AND 
			event_name = 'Add to Cart'
		)
		OR
		event_name='Purchase'
	GROUP BY visit_id, cookie_id, page_name
)
SELECT TOP 3
	page_name AS "product_name",
	COUNT(page_name) AS "total_purchases"
FROM purchase_cte p
WHERE EXISTS (
	SELECT
		1
	FROM purchase_cte
	WHERE purchase IS NOT NULL AND visit_id = p.visit_id AND cookie_id = p.cookie_id
) AND page_name <> 'Confirmation'
GROUP BY page_name
ORDER BY total_purchases DESC;
GO



















---------------------------------------------------------------------------------------------> 3. Product Funnel Analysis <---------------------------------------------------------------------------------------------

--Using a single SQL query - create a new output table which has the following details:

--How many times was each product viewed?
--How many times was each product added to cart?
--How many times was each product added to a cart but not purchased (abandoned)?
--How many times was each product purchased?
--Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.




--------------TABLE 1

--- check if any page is viewed more than one time before purchase by same visit_id and cookie_id ------------ result -> 0
WITH test_cte AS (
	SELECT e.*, event_name, page_name, ROW_NUMBER() OVER(PARTITION BY visit_id, cookie_id, event_name, page_name ORDER BY event_time) AS "row_no"
	FROM [clique_bait].[events] e
		JOIN [clique_bait].[event_identifier] ei
			ON e.event_type = ei.event_type
		JOIN [clique_bait].[page_hierarchy] ph
			ON e.page_id = ph.page_id
)
SELECT * FROM test_cte WHERE row_no>1;
--WHERE visit_id='c4120b' AND cookie_id='001652';
GO


--- assuming that each page is viewed atmost once (as per the above query result set) before purchase by same visit_id and cookie_id --------- in reality a person might revisit same page before purchase

-- version 1: events count on each procduct by particular visit_id and cookie_id
WITH purchase_cte AS (
	SELECT
		visit_id,
		cookie_id,
		SUM(
			CASE
				WHEN page_name='Salmon' THEN 1
			END
		) AS "salmon",
		SUM(
			CASE
				WHEN page_name='Kingfish' THEN 1
			END
		) AS "kingfish",
		SUM(
			CASE
				WHEN page_name='Tuna' THEN 1
			END
		) AS "tuna",
		SUM(
			CASE
				WHEN page_name='Russian Caviar' THEN 1
			END
		) AS "russian_caviar",
		SUM(
			CASE
				WHEN page_name='Black Truffle' THEN 1
			END
		) AS "black_truffle",
		SUM(
			CASE
				WHEN page_name='Abalone' THEN 1
			END
		) AS "abalone",
		SUM(
			CASE
				WHEN page_name='Lobster' THEN 1
			END
		) AS "lobster",
		SUM(
			CASE
				WHEN page_name='Crab' THEN 1 
			END
		)  AS "crab",
		SUM(
			CASE
				WHEN page_name='Oyster' THEN 1 
			END
		)  AS "oyster",
		SUM(
			CASE
				WHEN event_name='Page View' THEN 1
			END
		) AS "page_view",
		SUM(
			CASE
				WHEN event_name='Add to Cart' THEN 1
			END
		) AS "add_to_cart",
		SUM(
			CASE
				WHEN event_name='Purchase' THEN 1
			END
		) AS "purchase"
	FROM [clique_bait].[events] e
	JOIN [clique_bait].[event_identifier] ei
		ON e.event_type = ei.event_type
	JOIN [clique_bait].[page_hierarchy] ph
		ON e.page_id = ph.page_id
	WHERE 
		(
			product_id IS NOT NULL 
			AND 
			event_name IN ('Page View', 'Add to Cart')
		)
		OR
		event_name='Purchase'
	GROUP BY visit_id, cookie_id
)
SELECT * FROM purchase_cte
WHERE purchase IS NOT NULL;
GO

-- version 2: events count on each procduct
WITH purchase_cte AS (
	SELECT
		visit_id,
		cookie_id,
		SUM(
			CASE
				WHEN page_name='Salmon' THEN 1
			END
		) AS "salmon",
		SUM(
			CASE
				WHEN page_name='Kingfish' THEN 1
			END
		) AS "kingfish",
		SUM(
			CASE
				WHEN page_name='Tuna' THEN 1
			END
		) AS "tuna",
		SUM(
			CASE
				WHEN page_name='Russian Caviar' THEN 1
			END
		) AS "russian_caviar",
		SUM(
			CASE
				WHEN page_name='Black Truffle' THEN 1
			END
		) AS "black_truffle",
		SUM(
			CASE
				WHEN page_name='Abalone' THEN 1
			END
		) AS "abalone",
		SUM(
			CASE
				WHEN page_name='Lobster' THEN 1
			END
		) AS "lobster",
		SUM(
			CASE
				WHEN page_name='Crab' THEN 1 
			END
		)  AS "crab",
		SUM(
			CASE
				WHEN page_name='Oyster' THEN 1 
			END
		)  AS "oyster",
		SUM(
			CASE
				WHEN event_name='Page View' THEN 1
			END
		) AS "page_view",
		SUM(
			CASE
				WHEN event_name='Add to Cart' THEN 1
			END
		) AS "add_to_cart",
		SUM(
			CASE
				WHEN event_name='Purchase' THEN 1
			END
		) AS "purchase"
	FROM [clique_bait].[events] e
	JOIN [clique_bait].[event_identifier] ei
		ON e.event_type = ei.event_type
	JOIN [clique_bait].[page_hierarchy] ph
		ON e.page_id = ph.page_id
	WHERE 
		(
			product_id IS NOT NULL 
			AND 
			event_name IN ('Page View', 'Add to Cart')
		)
		OR
		event_name='Purchase'
	GROUP BY visit_id, cookie_id
	)
(
	SELECT
		'abandoned' AS "total",
		SUM(	
			CASE 
				WHEN salmon>1 THEN 1
				ELSE 0
			END
		) AS "salmon",
		SUM(	
			CASE 
				WHEN kingfish>1 THEN 1
				ELSE 0
			END
		) AS "kingfish",
		SUM(	
			CASE 
				WHEN tuna>1 THEN 1
				ELSE 0
			END
		) AS "tuna",
		SUM(	
			CASE 
				WHEN russian_caviar>1 THEN 1
				ELSE 0
			END
		) AS "russian_caviar",
		SUM(	
			CASE 
				WHEN black_truffle>1 THEN 1
				ELSE 0
			END
		) AS "black_truffle",
		SUM(	
			CASE 
				WHEN abalone>1 THEN 1
				ELSE 0
			END
		) AS "abalone",
		SUM(	
			CASE 
				WHEN lobster>1 THEN 1
				ELSE 0
			END
		) AS "lobster",
		SUM(	
			CASE 
				WHEN crab>1 THEN 1
				ELSE 0
			END
		) AS "crab",
		SUM(	
			CASE 
				WHEN oyster>1 THEN 1
				ELSE 0
			END
		) AS "oyster"
	FROM purchase_cte
	WHERE purchase IS NULL
)
UNION
(
	SELECT
		'add_to_cart' AS "total",
		SUM(	
			CASE 
				WHEN salmon>1 THEN 1
				ELSE 0
			END
		) AS "salmon",
		SUM(	
			CASE 
				WHEN kingfish>1 THEN 1
				ELSE 0
			END
		) AS "kingfish",
		SUM(	
			CASE 
				WHEN tuna>1 THEN 1
				ELSE 0
			END
		) AS "tuna",
		SUM(	
			CASE 
				WHEN russian_caviar>1 THEN 1
				ELSE 0
			END
		) AS "russian_caviar",
		SUM(	
			CASE 
				WHEN black_truffle>1 THEN 1
				ELSE 0
			END
		) AS "black_truffle",
		SUM(	
			CASE 
				WHEN abalone>1 THEN 1
				ELSE 0
			END
		) AS "abalone",
		SUM(	
			CASE 
				WHEN lobster>1 THEN 1
				ELSE 0
			END
		) AS "lobster",
		SUM(	
			CASE 
				WHEN crab>1 THEN 1
				ELSE 0
			END
		) AS "crab",
		SUM(	
			CASE 
				WHEN oyster>1 THEN 1
				ELSE 0
			END
		) AS "oyster"
	FROM purchase_cte
)
UNION
(
	SELECT
		'page_view' AS "total",
		COUNT(salmon) AS "salmon",
		COUNT(kingfish) AS "kingfish",
		COUNT(tuna) AS "tuna",
		COUNT(russian_caviar) AS "russian_caviar",
		COUNT(black_truffle) AS "black_truffle",
		COUNT(abalone) AS "abalone",
		COUNT(lobster) AS "lobster",
		COUNT(crab) AS "crab",
		COUNT(oyster) AS "oyster"
	FROM purchase_cte
)
UNION
(
	SELECT
		'purchase' AS total,
		SUM(	
			CASE 
				WHEN salmon>1 THEN 1
				ELSE 0
			END
		) AS "salmon",
		SUM(	
			CASE 
				WHEN kingfish>1 THEN 1
				ELSE 0
			END
		) AS "kingfish",
		SUM(	
			CASE 
				WHEN tuna>1 THEN 1
				ELSE 0
			END
		) AS "tuna",
		SUM(	
			CASE 
				WHEN russian_caviar>1 THEN 1
				ELSE 0
			END
		) AS "russian_caviar",
		SUM(	
			CASE 
				WHEN black_truffle>1 THEN 1
				ELSE 0
			END
		) AS "black_truffle",
		SUM(	
			CASE 
				WHEN abalone>1 THEN 1
				ELSE 0
			END
		) AS "abalone",
		SUM(	
			CASE 
				WHEN lobster>1 THEN 1
				ELSE 0
			END
		) AS "lobster",
		SUM(	
			CASE 
				WHEN crab>1 THEN 1
				ELSE 0
			END
		) AS "crab",
		SUM(	
			CASE 
				WHEN oyster>1 THEN 1
				ELSE 0
			END
		) AS "oyster"
	FROM purchase_cte
	WHERE purchase IS NOT NULL
)
GO

-- final table created by transposing version 2 result set
-- normal transpose can be obtain by using unpivot on a table and then applying pivot on unpivoted table 
-- method 1 -- 28% relative cost
WITH purchase_cte AS (
	SELECT
		visit_id,
		cookie_id,
		SUM(
			CASE
				WHEN page_name='Salmon' THEN 1
			END
		) AS "salmon",
		SUM(
			CASE
				WHEN page_name='Kingfish' THEN 1
			END
		) AS "kingfish",
		SUM(
			CASE
				WHEN page_name='Tuna' THEN 1
			END
		) AS "tuna",
		SUM(
			CASE
				WHEN page_name='Russian Caviar' THEN 1
			END
		) AS "russian_caviar",
		SUM(
			CASE
				WHEN page_name='Black Truffle' THEN 1
			END
		) AS "black_truffle",
		SUM(
			CASE
				WHEN page_name='Abalone' THEN 1
			END
		) AS "abalone",
		SUM(
			CASE
				WHEN page_name='Lobster' THEN 1
			END
		) AS "lobster",
		SUM(
			CASE
				WHEN page_name='Crab' THEN 1 
			END
		)  AS "crab",
		SUM(
			CASE
				WHEN page_name='Oyster' THEN 1 
			END
		)  AS "oyster",
		SUM(
			CASE
				WHEN event_name='Page View' THEN 1
			END
		) AS "page_view",
		SUM(
			CASE
				WHEN event_name='Add to Cart' THEN 1
			END
		) AS "add_to_cart",
		SUM(
			CASE
				WHEN event_name='Purchase' THEN 1
			END
		) AS "purchase"
	FROM [clique_bait].[events] e
	JOIN [clique_bait].[event_identifier] ei
		ON e.event_type = ei.event_type
	JOIN [clique_bait].[page_hierarchy] ph
		ON e.page_id = ph.page_id
	WHERE 
		(
			product_id IS NOT NULL 
			AND 
			event_name IN ('Page View', 'Add to Cart')
		)
		OR
		event_name='Purchase'
	GROUP BY visit_id, cookie_id
)
SELECT *
INTO [clique_bait].[product_statistics]
FROM
(
	
	SELECT total, product_name, value
	FROM (
		SELECT
			'abandoned' AS "total",
			SUM(	
				CASE 
					WHEN salmon>1 THEN 1
					ELSE 0
				END
			) AS "salmon",
			SUM(	
				CASE 
					WHEN kingfish>1 THEN 1
					ELSE 0
				END
			) AS "kingfish",
			SUM(	
				CASE 
					WHEN tuna>1 THEN 1
					ELSE 0
				END
			) AS "tuna",
			SUM(	
				CASE 
					WHEN russian_caviar>1 THEN 1
					ELSE 0
				END
			) AS "russian_caviar",
			SUM(	
				CASE 
					WHEN black_truffle>1 THEN 1
					ELSE 0
				END
			) AS "black_truffle",
			SUM(	
				CASE 
					WHEN abalone>1 THEN 1
					ELSE 0
				END
			) AS "abalone",
			SUM(	
				CASE 
					WHEN lobster>1 THEN 1
					ELSE 0
				END
			) AS "lobster",
			SUM(	
				CASE 
					WHEN crab>1 THEN 1
					ELSE 0
				END
			) AS "crab",
			SUM(	
				CASE 
					WHEN oyster>1 THEN 1
					ELSE 0
				END
			) AS "oyster"
		FROM purchase_cte
		WHERE purchase IS NULL

		UNION

		SELECT
			'add_to_cart' AS "total",
			SUM(	
				CASE 
					WHEN salmon>1 THEN 1
					ELSE 0
				END
			) AS "salmon",
			SUM(	
				CASE 
					WHEN kingfish>1 THEN 1
					ELSE 0
				END
			) AS "kingfish",
			SUM(	
				CASE 
					WHEN tuna>1 THEN 1
					ELSE 0
				END
			) AS "tuna",
			SUM(	
				CASE 
					WHEN russian_caviar>1 THEN 1
					ELSE 0
				END
			) AS "russian_caviar",
			SUM(	
				CASE 
					WHEN black_truffle>1 THEN 1
					ELSE 0
				END
			) AS "black_truffle",
			SUM(	
				CASE 
					WHEN abalone>1 THEN 1
					ELSE 0
				END
			) AS "abalone",
			SUM(	
				CASE 
					WHEN lobster>1 THEN 1
					ELSE 0
				END
			) AS "lobster",
			SUM(	
				CASE 
					WHEN crab>1 THEN 1
					ELSE 0
				END
			) AS "crab",
			SUM(	
				CASE 
					WHEN oyster>1 THEN 1
					ELSE 0
				END
			) AS "oyster"
		FROM purchase_cte

		UNION

		SELECT
			'page_view' AS "total",
			COUNT(salmon) AS "salmon",
			COUNT(kingfish) AS "kingfish",
			COUNT(tuna) AS "tuna",
			COUNT(russian_caviar) AS "russian_caviar",
			COUNT(black_truffle) AS "black_truffle",
			COUNT(abalone) AS "abalone",
			COUNT(lobster) AS "lobster",
			COUNT(crab) AS "crab",
			COUNT(oyster) AS "oyster"
		FROM purchase_cte

		UNION

		SELECT
			'purchase' AS total,
			SUM(	
				CASE 
					WHEN salmon>1 THEN 1
					ELSE 0
				END
			) AS "salmon",
			SUM(	
				CASE 
					WHEN kingfish>1 THEN 1
					ELSE 0
				END
			) AS "kingfish",
			SUM(	
				CASE 
					WHEN tuna>1 THEN 1
					ELSE 0
				END
			) AS "tuna",
			SUM(	
				CASE 
					WHEN russian_caviar>1 THEN 1
					ELSE 0
				END
			) AS "russian_caviar",
			SUM(	
				CASE 
					WHEN black_truffle>1 THEN 1
					ELSE 0
				END
			) AS "black_truffle",
			SUM(	
				CASE 
					WHEN abalone>1 THEN 1
					ELSE 0
				END
			) AS "abalone",
			SUM(	
				CASE 
					WHEN lobster>1 THEN 1
					ELSE 0
				END
			) AS "lobster",
			SUM(	
				CASE 
					WHEN crab>1 THEN 1
					ELSE 0
				END
			) AS "crab",
			SUM(	
				CASE 
					WHEN oyster>1 THEN 1
					ELSE 0
				END
			) AS "oyster"
		FROM purchase_cte
		WHERE purchase IS NOT NULL
	) tb
	CROSS APPLY (
		VALUES ('salmon', salmon), ('kingfish', kingfish), ('tuna', tuna), ('russian_caviar', russian_caviar), ('black_truffle', black_truffle), ('abalone', abalone), ('lobster', lobster), ('crab', crab), ('oyster', oyster)
	) c (product_name, value)

)src
PIVOT
(
	MAX(value)
	FOR total IN (abandoned, add_to_cart, purchase, page_view)
) upvt
GO


-- method 2 - 46% relative cost
-- page_view, add_to_cart, puchase flag for each visit
WITH event_count_cte AS (
	SELECT 
		visit_id,
		cookie_id,
		ph.product_id,
		ph.page_name AS product_name,
		ph.product_category,
		SUM(
			CASE 
				WHEN e.event_type = 1 THEN 1 
				ELSE NULL 
			END
		) AS "page_view_flag",
		SUM(
			CASE 
				WHEN e.event_type = 2 THEN 1 
				ELSE NULL 
			END
		) AS "add_to_cart_flag", 
		SUM(
			CASE 
				WHEN page_name = 'Confirmation' THEN 1 
				ELSE NULL 
			END
		)  AS "purchase_flag"
	FROM [clique_bait].[events] e
	JOIN [clique_bait].[event_identifier] ei
		ON e.event_type = ei.event_type
	JOIN [clique_bait].[page_hierarchy] ph
		ON e.page_id = ph.page_id
	GROUP BY visit_id, cookie_id, ph.product_id, ph.page_name, ph.product_category
)
SELECT
	product_name,
	SUM(page_view_flag) AS "page_view",
	SUM(add_to_cart_flag) AS "add_to_cart",
	SUM(purchase_flag + add_to_cart_flag) / 2 AS "purchase",
	SUM(add_to_cart_flag) - (SUM(purchase_flag + add_to_cart_flag) / 2) AS "abandoned"
	-- another way to calculate purchase and abandoned
	--SUM(
	--	CASE
	--		WHEN add_to_cart_flag = purchase_flag THEN 1
	--		ELSE 0
	--	END
	--) AS "purchase",
	--SUM(
	--	CASE
	--		WHEN (add_to_cart_flag = 1) AND (purchase_flag IS NULL) THEN 1
	--		ELSE 0
	--	END
	--)  AS "abandoned"
INTO [clique_bait].[product_statistics]
FROM event_count_cte
WHERE product_id IS NOT NULL
GROUP BY product_name;
GO


-- method 3 -- 26% relative cost 
-- page_view and cart_add flag for each visit
WITH page_view_cart_add_event_cte AS (
	SELECT 
		e.visit_id,
		ph.product_id,
		ph.page_name AS product_name,
		ph.product_category,
		SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS "page_view", 
		SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS "cart_add"
	FROM clique_bait.events AS e
	JOIN clique_bait.page_hierarchy AS ph
		ON e.page_id = ph.page_id
	WHERE product_id IS NOT NULL
	GROUP BY e.visit_id, ph.product_id, ph.page_name, ph.product_category
),
-- finding all visits with purchase
visit_with_purchase_cte AS ( 
	SELECT 
		DISTINCT visit_id
	FROM clique_bait.events
	WHERE event_type = 3 
),
-- above two cte are join to get page_view, cart_add and purchase flags for each visit
all_visit_purchase_cte AS ( 
	SELECT 
		pc.visit_id, 
		pc.product_id, 
		pc.product_name, 
		pc.product_category, 
		pc.page_view, 
		pc.cart_add,
		CASE 
			WHEN vp.visit_id IS NOT NULL THEN 1 
			ELSE 0 
		END AS "purchase"
	FROM page_view_cart_add_event_cte AS pc
	LEFT JOIN visit_with_purchase_cte AS vp
		ON pc.visit_id = vp.visit_id
)
SELECT 
	product_name, 
	product_category, 
	SUM(page_view) AS "page_view",
	SUM(cart_add) AS "cart_add", 
	SUM(
		CASE 
			WHEN cart_add = 1 AND purchase = 0 THEN 1 
			ELSE 0 
		END
	) AS "abandoned",
	SUM(
		CASE 
			WHEN cart_add = 1 AND purchase = 1 THEN 1 
			ELSE 0 
		END
	) AS "purchase"
INTO [clique_bait].[product_statistics]
FROM all_visit_purchase_cte
GROUP BY product_id, product_name, product_category;
GO






--------------TABLE 2 
SELECT * FROM [clique_bait].[product_statistics]

SELECT
	*
INTO #product_category
FROM [clique_bait].[product_statistics]

ALTER TABLE #product_category ADD product_category VARCHAR(10);

UPDATE #product_category SET product_category = 'Fish' WHERE product_name IN ('salmon', 'kingfish', 'tuna')

UPDATE #product_category SET product_category = 'Luxury' WHERE product_name IN ('russian_caviar', 'black_truffle')

UPDATE #product_category SET product_category = 'Shellfish' WHERE product_name IN ('abalone', 'lobster', 'crab', 'oyster')

 SELECT
	product_category,
	SUM(abandoned) AS "abandoned",
	SUM(add_to_cart) AS "add_to_cart",
	SUM(purchase) AS "purchase",
	SUM(page_view) AS "page_view"
INTO [clique_bait].[product_category_statistics]
FROM #product_category
GROUP BY product_category;
GO

DROP TABLE IF EXISTS #product_category

SELECT * from [clique_bait].[product_category_statistics]





--Use your 2 new output tables - answer the following questions:

---> 1) Which product had the most views, cart adds and purchases?
SELECT TOP 1
	FIRST_VALUE(product_name) OVER(ORDER BY page_view DESC) AS "most_views",
	FIRST_VALUE(product_name) OVER(ORDER BY add_to_cart DESC) AS "most_cart_adds",
	FIRST_VALUE(product_name) OVER(ORDER BY purchase DESC) AS "most_purchase"
FROM [clique_bait].[product_statistics];
GO





---> 2) Which product was most likely to be abandoned?

-- method 1 -- relative cost: 50%
SELECT TOP 1
	FIRST_VALUE(product_name) OVER(ORDER BY abandoned DESC) AS "most_abandoned"
FROM [clique_bait].[product_statistics];
GO


--- method 2 -- relative cost: 50%
SELECT TOP 1
	product_name  AS "most_abandoned"
FROM [clique_bait].[product_statistics]
ORDER BY abandoned DESC;
GO





---> 3) Which product had the highest view to purchase percentage?

SELECT TOP 1
	*,
	ROUND(
		(
			purchase / CAST(page_view AS REAL) 
		) * 100,
		2
	) AS "view_to_purchase (%)"
FROM [clique_bait].[product_statistics]
ORDER BY [view_to_purchase (%)] DESC;
GO





---> 4) What is the average conversion rate from view to cart add?
SELECT
	ROUND(
		AVG(
			add_to_cart / CAST(page_view AS REAL)
		) * 100,
		2
	) AS "view_to_cart (%)"
FROM [clique_bait].[product_statistics];
GO




---> 5) What is the average conversion rate from cart add to purchase?
SELECT
	ROUND(
		AVG(
			purchase / CAST(add_to_cart AS REAL)
		) * 100,
		2
	) AS "cart_to_purchase (%)"
FROM [clique_bait].[product_statistics];
GO



















---------------------------------------------------------------------------------------------> 3. Campaigns Analysis <---------------------------------------------------------------------------------------------

--Generate a table that has 1 single row for every unique visit_id record and has the following columns:

--user_id
--visit_id
--visit_start_time: the earliest event_time for each visit
--page_views: count of page views for each visit
--cart_adds: count of product cart add events for each visit
--purchase: 1/0 flag if a purchase event exists for each visit
--campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
--impression: count of ad impressions for each visit
--click: count of ad clicks for each visit
--(Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)
--Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - 
--bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.

--Some ideas you might want to investigate further include:

--Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
--Does clicking on an impression lead to higher purchase rates?
--What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
--What metrics can you use to quantify the success or failure of each campaign compared to eachother?


SELECT
	[user_id],
	visit_id,
	MIN(event_time) AS "visit_start_time",
	SUM(CASE WHEN e.event_type=1 THEN 1 ELSE 0 END) AS "page_views",
	SUM(CASE WHEN e.event_type=2 THEN 1 ELSE 0 END) AS "cart_adds",
	SUM(CASE WHEN e.event_type=3 THEN 1 ELSE 0 END) AS "purchase",
	campaign_name,
	SUM(CASE WHEN e.event_type=4 THEN 1 ELSE 0 END) AS "ad_impression",
	SUM(CASE WHEN e.event_type=5 THEN 1 ELSE 0 END) AS "ad_click",
	STRING_AGG(CASE WHEN e.event_type=2 THEN page_name ELSE NULL END, ', ') WITHIN GROUP (ORDER BY sequence_number) AS "cart_products"
FROM [clique_bait].[events] e
JOIN [clique_bait].[event_identifier] ei
	ON e.event_type = ei.event_type
JOIN [clique_bait].[page_hierarchy] ph
	ON e.page_id = ph.page_id
JOIN [clique_bait].[users] u
	ON e.cookie_id = u.cookie_id
LEFT JOIN [clique_bait].[campaign_identifier] c
	ON event_time BETWEEN c.start_date AND c.end_date
GROUP BY [user_id], visit_id, campaign_name
ORDER BY [user_id], visit_start_time
GO
