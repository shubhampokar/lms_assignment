---------------------------------------------------------------------------------------------> High Level Sales Analysis <---------------------------------------------------------------------------------------------

---> 1) What was the total quantity sold for all products?

-- total quantity sold of all products
SELECT
	product_name,
	SUM(qty) AS "total_qty_sold"
FROM [balanced_tree].[sales] s
JOIN [balanced_tree].[product_details] pd
	ON s.prod_id = pd.product_id
GROUP BY product_name;
GO

-- total quantity sold
SELECT
	SUM(qty) AS "total_qty_sold"
FROM [balanced_tree].[sales];
GO




---> 2) What is the total generated revenue for all products before discounts?
SELECT
	product_name,
	SUM(s.price * s.qty) AS "total_revenue_without_discount"
FROM [balanced_tree].[sales] s
JOIN [balanced_tree].[product_details] pd
	ON s.prod_id = pd.product_id
GROUP BY product_name;
GO

-- total revenue
SELECT
	SUM(price * qty) AS "total_revenue_without_discount"
FROM [balanced_tree].[sales];
GO




---> 3) What was the total discount amount for all products?
SELECT
	product_name,
	ROUND(
		SUM(s.price * s.qty * (CAST(discount AS REAL)/100)),
		2
	) AS "total_discount"
FROM [balanced_tree].[sales] s
JOIN [balanced_tree].[product_details] pd
	ON s.prod_id = pd.product_id
GROUP BY product_name;
GO

-- total discount
SELECT
	ROUND(
		SUM(
			price * qty * (CAST(discount AS REAL) / 100)
		),
		2
	) AS "total_discount"
FROM [balanced_tree].[sales];
GO


















---------------------------------------------------------------------------------------------> Transaction Analysis <---------------------------------------------------------------------------------------------
---> 1) How many unique transactions were there?
SELECT 
	COUNT(DISTINCT txn_id) AS "unique_transactions"
FROM [balanced_tree].[sales];
GO




---> 2) What is the average unique products purchased in each transaction?
WITH transaction_cte AS(
	SELECT 
		txn_id,
		COUNT(prod_id) AS "unique_prod"
	FROM [balanced_tree].[sales]
	GROUP BY txn_id
)
SELECT 
	AVG(unique_prod) AS "avg_product_per_transaction"
FROM transaction_cte;
GO




---> 3) What are the 25th, 50th and 75th percentile values for the revenue per transaction?
WITH transaction_cte AS(
	SELECT 
		txn_id,
		SUM(price * qty * (1 - (CAST(discount AS REAL) / 100))) AS "txn_amount"
		--PERCENT_RANK() OVER(ORDER BY SUM(price * qty * (1 - (CAST(discount AS REAL) / 100)))) AS "percent_rank"
	FROM [balanced_tree].[sales]
	GROUP BY txn_id
)
SELECT TOP 1
	ROUND(
		PERCENTILE_DISC(0.25) WITHIN GROUP(ORDER BY txn_amount) OVER(), 
		2
	) AS "25_perc_disc_rev",
	ROUND(
		PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY txn_amount) OVER(), 
		2
	) AS "50_perc_disc_rev",
	ROUND(
		PERCENTILE_DISC(0.75) WITHIN GROUP(ORDER BY txn_amount) OVER(), 
		2
	) AS "75_perc_disc_rev"
FROM transaction_cte;
GO





---> 4) What is the average discount value per transaction?
WITH transaction_cte AS(
	SELECT 
		txn_id,
		SUM(price * qty * (CAST(discount AS REAL) / 100)) AS "discount_amount"
	FROM [balanced_tree].[sales]
	GROUP BY txn_id
)
SELECT 
	ROUND(AVG(discount_amount), 2) AS "avg_discount_per_txn"
FROM transaction_cte;
GO




---> 5) What is the percentage split of all transactions for members vs non-members?

-- for txn_amount --- member txn revenue is 60.31% and non-member is (100 - 60.31) = 39.69%
WITH transaction_cte AS(
	SELECT 
		txn_id,
		member,
		SUM(price * qty * (1 - (CAST(discount AS REAL) / 100))) AS "txn_amount"
	FROM [balanced_tree].[sales]
	GROUP BY txn_id, member
)
SELECT 
	(
		SUM(
			CASE 
				WHEN member = 1 THEN txn_amount
				ELSE 0
			END
		) / SUM(txn_amount)
	) * 100 AS "member_txn (%)"
FROM transaction_cte;
GO


-- for txn_count --- member txn is 60.2% and non-member is 39.8%
-- method 1 using case -- relative cost: 57%
SELECT 
	(
		COUNT(DISTINCT
			CASE 
				WHEN member = 0 THEN txn_id
				ELSE NULL
			END
		) / CAST(COUNT(DISTINCT txn_id) AS REAL)
	) * 100 AS "member_txn (%)",
	(
		COUNT(DISTINCT
			CASE 
				WHEN member = 1 THEN txn_id
				ELSE NULL
			END
		) / CAST(COUNT(DISTINCT txn_id) AS REAL)
	) * 100 AS "member_txn (%)"
FROM [balanced_tree].[sales];
GO

-- method 2 usinf window function -- relative cost: 43%
SELECT
	DISTINCT
	member,
	(
		COUNT(txn_id) OVER(PARTITION BY member ORDER BY member) / CAST(COUNT(txn_id) OVER() AS REAL)
	) * 100 AS "member_txn (%)"
FROM [balanced_tree].[sales]
GROUP BY member, txn_id;
GO





---> 6) What is the average revenue for member transactions and non-member transactions?

-- method 1 -- relative cost: 48%
WITH transaction_cte AS(
	SELECT 
		txn_id,
		member,
		SUM(price * qty * (1 - (CAST(discount AS REAL) / 100))) AS "txn_amount"
	FROM [balanced_tree].[sales]
	GROUP BY txn_id, member
)
SELECT 
	ROUND(
		AVG(
			CASE 
				WHEN member = 1 THEN txn_amount
				ELSE NULL
			END
		),
		2
	) AS "member_txn",
	ROUND(
		AVG(
			CASE 
				WHEN member = 0 THEN txn_amount
				ELSE NULL
			END
		),
		2
	) AS "non_member_txn"
FROM transaction_cte;
GO


-- method 2 -- relative cost: 52%
SELECT TOP 1
	ROUND(
		AVG(
			CASE 
				WHEN member = 1 THEN SUM(price * qty * (1 - (CAST(discount AS REAL) / 100)))
				ELSE NULL
			END
		) OVER(),
		2
	) AS "member_txn",
	ROUND(
		AVG(
			CASE 
				WHEN member = 0 THEN SUM(price * qty * (1 - (CAST(discount AS REAL) / 100)))
				ELSE NULL
			END
		) OVER(),
		2
	) AS "non_member_txn"
FROM [balanced_tree].[sales]
GROUP BY txn_id, member;
GO
















---------------------------------------------------------------------------------------------> Product Analysis <---------------------------------------------------------------------------------------------

---> 1) What are the top 3 products by total revenue before discount?
SELECT TOP 3
	product_name,
	SUM(s.price * qty) AS "total_revenue"
FROM [balanced_tree].[sales] s
JOIN [balanced_tree].[product_details] pd
	ON s.prod_id = pd.product_id
GROUP BY product_name
ORDER BY total_revenue DESC;
GO




---> 2) What is the total quantity, revenue and discount for each segment?
SELECT
	segment_name,
	SUM(qty) AS "total_quantity",
	ROUND(
		SUM(s.price * qty * (1 - (CAST(discount AS REAL) / 100))),
		2
	) AS "total_revenue",
	ROUND(
		SUM(s.price * qty * (CAST(discount AS REAL) / 100)),
		2
	) AS "total_discount"
FROM [balanced_tree].[sales] s
JOIN [balanced_tree].[product_details] pd
	ON s.prod_id = pd.product_id
GROUP BY segment_name;
GO




---> 3) What is the top selling product for each segment?
WITH segment_qty_cte AS (
	SELECT
		segment_name,
		product_name,
		SUM(qty) AS "total_quantity",
		RANK() OVER(PARTITION BY segment_name ORDER BY SUM(qty) DESC) AS "rank_no"
	FROM [balanced_tree].[sales] s
	JOIN [balanced_tree].[product_details] pd
		ON s.prod_id = pd.product_id
	GROUP BY segment_name, product_name
)
SELECT 
	segment_name, product_name, total_quantity
FROM segment_qty_cte
WHERE rank_no = 1;
GO




---> 4) What is the total quantity, revenue and discount for each category?
SELECT
	category_name,
	SUM(qty) AS "total_quantity",
	ROUND(
		SUM(s.price * qty * (1 - (CAST(discount AS REAL) / 100))),
		2
	) AS "total_revenue",
	ROUND(
		SUM(s.price * qty * (CAST(discount AS REAL) / 100)),
		2
	) AS "total_discount"
FROM [balanced_tree].[sales] s
JOIN [balanced_tree].[product_details] pd
	ON s.prod_id = pd.product_id
GROUP BY category_name;
GO




---> 5) What is the top selling product for each category?
WITH category_qty_cte AS (
	SELECT
		category_name,
		product_name,
		SUM(qty) AS "total_quantity",
		RANK() OVER(PARTITION BY category_name ORDER BY SUM(qty) DESC) AS "rank_no"
	FROM [balanced_tree].[sales] s
	JOIN [balanced_tree].[product_details] pd
		ON s.prod_id = pd.product_id
	GROUP BY category_name, product_name
)
SELECT 
	category_name, product_name, total_quantity
FROM category_qty_cte
WHERE rank_no = 1;
GO




---> 6) What is the percentage split of revenue by product for each segment?
WITH segment_txn_cte AS (
	SELECT
		segment_name,
		product_name,
		SUM(s.price * qty * (1 - (CAST(discount AS REAL) / 100))) AS "prod_revenue"
	FROM [balanced_tree].[sales] s
	JOIN [balanced_tree].[product_details] pd
		ON s.prod_id = pd.product_id
	GROUP BY segment_name, product_name
)
SELECT 
	segment_name, product_name,
	ROUND(
		(
			prod_revenue / SUM(prod_revenue) OVER(PARTITION BY segment_name ORDER BY prod_revenue ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
		) * 100,
		2
	) AS "revenue_percentage_split"
FROM segment_txn_cte;
GO




---> 7) What is the percentage split of revenue by segment for each category?
WITH segment_txn_cte AS (
	SELECT
		category_name,
		segment_name,
		SUM(s.price * qty * (1 - (CAST(discount AS REAL) / 100))) AS "cat_revenue"
	FROM [balanced_tree].[sales] s
	JOIN [balanced_tree].[product_details] pd
		ON s.prod_id = pd.product_id
	GROUP BY category_name, segment_name
)
SELECT 
	category_name, segment_name,
	ROUND(
		(
			cat_revenue / SUM(cat_revenue) OVER(PARTITION BY category_name ORDER BY cat_revenue ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
		) * 100,
		2
	) AS "revenue_percentage_split"
FROM segment_txn_cte;
GO




---> 8) What is the percentage split of total revenue by category?
-- women: 44.63% and men: 55.37%
WITH segment_txn_cte AS (
	SELECT
		category_name,
		SUM(s.price * qty * (1 - (CAST(discount AS REAL) / 100))) AS "cat_revenue"
	FROM [balanced_tree].[sales] s
	JOIN [balanced_tree].[product_details] pd
		ON s.prod_id = pd.product_id
	GROUP BY category_name
)
SELECT 
	ROUND(
		(
			SUM(
				CASE
					WHEN category_name = 'Mens' THEN cat_revenue
					ELSE 0
				END
			) / SUM(cat_revenue)
		) * 100,
		2
	) AS "men_revenue_percentage_split",
	ROUND(
		(
			SUM(
				CASE
					WHEN category_name = 'Womens' THEN cat_revenue
					ELSE 0
				END
			) / SUM(cat_revenue)
		) * 100,
		2
	) AS "women_revenue_percentage_split"
FROM segment_txn_cte;
GO





---> 9) What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
SELECT
	product_name,
	COUNT(txn_id) / (SELECT CAST(COUNT(DISTINCT txn_id) AS REAL) FROM [balanced_tree].[sales]) AS "transaction_penetration"
FROM [balanced_tree].[sales] s
JOIN [balanced_tree].[product_details] pd
	ON s.prod_id = pd.product_id
GROUP BY product_name
ORDER BY transaction_penetration DESC;
GO



---> 10) What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
WITH products AS(
	SELECT 
		txn_id,
		product_name
	FROM [balanced_tree].[sales] AS s
	JOIN [balanced_tree].[product_details] pd 
		ON s.prod_id = pd.product_id
),
-- create all possible three pairs of product within same txn using self join
three_product_pair_cte AS (
	SELECT 
		p1.product_name AS "product_1",
		p2.product_name AS "product_2",
		p3.product_name AS "product_3",
		COUNT(*) AS "times_bought_together",
		RANK() OVER(ORDER BY COUNT(*) DESC) AS "rank_no"
	FROM products AS p1 
	JOIN products AS p2 
		ON	p1.txn_id = p2.txn_id 
			AND 
			p1.product_name != p2.product_name	-- prevent pairing of same products in a txn
			AND 
			p1.product_name < p2.product_name	-- prevent duplicate pairing (doesn't create new pair by just by changing order as this is question of combination and not permuataion) because A,B == B,A
	JOIN products AS p3 
		ON	p1.txn_id = p3.txn_id
			AND 
			p1.product_name != p3.product_name	
			AND 
			p2.product_name != p3.product_name	
			AND 
			p1.product_name < p3.product_name
			AND 
			p2.product_name < p3.product_name
	GROUP BY p1.product_name, p2.product_name, p3.product_name
)
SELECT	
	product_1,
	product_2,
	product_3,
	times_bought_together
FROM three_product_pair_cte
WHERE rank_no=1
GO

















---------------------------------------------------------------------------------------------> Reporting Challenge <---------------------------------------------------------------------------------------------

---> Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.
---	 Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.
---	 He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).
---  Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks :)

CREATE OR ALTER VIEW balanced_tree.sales_details 
AS 
	SELECT 
		product_name,
		s.price, 
		qty,
		discount,
		txn_id,
		member,
		category_name,
		segment_name,		
		DATENAME(MONTH, start_txn_time) AS "txn_month",
		ROUND(s.price * qty * (1 - (discount / 100.0)), 2) AS "final_price"
	FROM [balanced_tree].[sales] s
	JOIN [balanced_tree].[product_details] pd
		ON s.prod_id = pd.product_id;
GO

CREATE OR ALTER PROCEDURE balanced_tree.product_wise_revenue
	@month nvarchar(10) = NULL
AS
	IF @month IS NULL 
		SELECT 
			product_name,
			SUM(final_price) AS "total_revenue"
		FROM balanced_tree.sales_details
		GROUP BY product_name
	ELSE
		SELECT 
			product_name,
			SUM(final_price) AS "total_revenue"
		FROM balanced_tree.sales_details
		WHERE txn_month = @month
		GROUP BY product_name
GO


EXEC balanced_tree.product_wise_revenue 
GO



CREATE OR ALTER PROCEDURE balanced_tree.report
AS
	--- Sales Analysis
	SELECT
		COALESCE(product_name, 'All Product') AS "product_name",
		SUM(qty) AS "total_quantity_sold",
		SUM(s.price * s.qty) AS "gross_revenue",
		ROUND(
			SUM(s.price * s.qty * (CAST(discount AS REAL)/100)),
			2
		) AS "total_discount",
		ROUND(
			SUM(s.price * s.qty * (1 - (CAST(discount AS REAL) / 100))),
			2
		) AS "net_revenue"
	FROM [balanced_tree].[sales] s
	JOIN [balanced_tree].[product_details] pd
		ON s.prod_id = pd.product_id
	GROUP BY ROLLUP(product_name)
	ORDER BY product_name;

	-- Transaction Analysis
	WITH transaction_cte AS(
		SELECT 
			txn_id,
			COUNT(prod_id) AS "unique_prod",
			SUM(price * qty * (CAST(discount AS REAL) / 100)) AS "discount_amount"
		FROM [balanced_tree].[sales]
		GROUP BY txn_id
	)
	SELECT
		COUNT(txn_id) AS "unique_transactions",
		AVG(unique_prod) AS "avg_product_per_transaction",
		ROUND(AVG(discount_amount), 2) AS "avg_discount_per_txn"
	FROM transaction_cte;

	WITH transaction_cte AS(
		SELECT 
			txn_id,
			SUM(price * qty * (1 - (CAST(discount AS REAL) / 100))) AS "txn_amount"
		FROM [balanced_tree].[sales]
		GROUP BY txn_id
	)
	SELECT TOP 1
		ROUND(
			PERCENTILE_DISC(0.25) WITHIN GROUP(ORDER BY txn_amount) OVER(), 
			2
		) AS "25_perc_disc_rev",
		ROUND(
			PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY txn_amount) OVER(), 
			2
		) AS "50_perc_disc_rev",
		ROUND(
			PERCENTILE_DISC(0.75) WITHIN GROUP(ORDER BY txn_amount) OVER(), 
			2
		) AS "75_perc_disc_rev"
	FROM transaction_cte;

	WITH transaction_cte AS(
		SELECT 
			txn_id,
			member,
			SUM(price * qty * (1 - (CAST(discount AS REAL) / 100))) AS "txn_amount"
		FROM [balanced_tree].[sales]
		GROUP BY txn_id, member
	)
	SELECT
		DISTINCT
		member,
		COUNT(txn_id) AS "total_txn",
		COUNT(member) AS "total_member",
		ROUND(SUM(txn_amount) OVER(), 2) AS "net_revenue",
		ROUND(AVG(txn_amount) OVER(PARTITION BY member ORDER BY member), 2) AS "avg_revenue",
		ROUND(
			(
				COUNT(txn_id) OVER(PARTITION BY member ORDER BY member) / CAST(COUNT(txn_id) OVER() AS REAL)
			) * 100,
			2
		) AS "txn_split (%)",
		ROUND(
			(
				SUM(txn_amount) OVER(PARTITION BY member ORDER BY member) / CAST(SUM(txn_amount) OVER() AS REAL)
			) * 100,
			2
		) AS "revenue_split (%)"
	FROM transaction_cte
	GROUP BY member, txn_id, txn_amount;

	-- Product Analysis
	WITH txn_stats AS (
		SELECT
			DISTINCT
			COALESCE(category_name, 'All Category') AS "category_name",
			COALESCE(segment_name, 'All Segment') AS "segment_name",
			COALESCE(product_name, 'All Product') AS "product_name",
			SUM(qty) AS "total_quantity",
			SUM(s.price * qty) AS "gross_revenue",
			ROUND(
				SUM(s.price * qty * (1 - (CAST(discount AS REAL) / 100))),
				2
			) AS "net_revenue",
			ROUND(
				SUM(s.price * qty * (CAST(discount AS REAL) / 100)),
				2
			) AS "total_discount"
		FROM [balanced_tree].[sales] s
		JOIN [balanced_tree].[product_details] pd
			ON s.prod_id = pd.product_id
		GROUP BY CUBE(product_name, segment_name), CUBE(segment_name, category_name)
	)
	SELECT
		*,
		ROUND(
			(
				net_revenue / SUM(net_revenue) OVER(PARTITION BY category_name, segment_name ORDER BY net_revenue ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
			) * 100 * 2,
			2
		) AS "revenue_percentage_split"
	FROM txn_stats
	ORDER BY category_name, segment_name, product_name;
GO

EXEC balanced_tree.report 
GO















---------------------------------------------------------------------------------------------> Bonus Challenge <---------------------------------------------------------------------------------------------

--Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

--Hint: you may want to consider using a recursive CTE to solve this problem!


--- solution using self join
SELECT
	product_id,
	price,
	cph.level_text + ' ' + pph.level_text + ' - ' + gph.level_text AS "product_name",
	gph.id AS "category_id",
	pph.id AS "segment_id",
	cph.id AS "style_id",
	gph.level_text AS "category_name",
	pph.level_text AS "segment_name",
	cph.level_text AS "style_name"
FROM [balanced_tree].[product_hierarchy] cph	--child
JOIN [balanced_tree].[product_hierarchy] pph	--parent
	ON cph.parent_id = pph.id
JOIN [balanced_tree].[product_hierarchy] gph	--grandparent
	ON pph.parent_id = gph.id
JOIN [balanced_tree].[product_prices] pp
	ON cph.id = pp.id;
GO