ALTER TABLE [fresh_segments].[interest_metrics]
ALTER COLUMN interest_id INT;
GO






---------------------------------------------------------------------------------------------> Data Exploration and Cleansing <---------------------------------------------------------------------------------------------
---> 1) Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
ALTER TABLE [fresh_segments].[interest_metrics]
ALTER COLUMN month_year VARCHAR(10);
GO


UPDATE [fresh_segments].[interest_metrics]
SET month_year = CONVERT(DATE, '01-'+month_year, 105);
GO


SELECT * FROM [fresh_segments].[interest_metrics];
GO


ALTER TABLE [fresh_segments].[interest_metrics]
ALTER COLUMN month_year DATE;
GO




---> 2) What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?

-- below query is wrong as COUNT(expression) returns the number of values in expression, which is a table column name or an expression that evaluates to a column of data. COUNT(expression) does not count NULL values.
SELECT
	month_year,
	COUNT(month_year) AS "count"
FROM [fresh_segments].[interest_metrics]
GROUP BY month_year
ORDER BY month_year;
GO


-- below query is right as COUNT(*) returns the number of rows in the table or view. COUNT(*) counts all rows, including ones that contain duplicate column values or NULL values.
SELECT
	month_year,
	COUNT(*) AS "count"
FROM [fresh_segments].[interest_metrics]
GROUP BY month_year
ORDER BY month_year;
GO

SELECT month_year 
FROM [fresh_segments].[interest_metrics] 
WHERE month_year IS NULL;
GO





---> 3) What do you think we should do with these null values in the fresh_segments.interest_metrics
SELECT * FROM [fresh_segments].[interest_metrics];
GO

--- Ans.	8.36% of data is missing in month_year column,
---			generally missing values are replaced with mean, median or mode value 
---			or
---			it can be dropped as per the scenario and correlation among data.
---			Assuming that data is inserted in order it was collected then we can update missing value with backfill (lagging value) or forwardfill (leading value) of same column




---> 4) How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?

-- given case
SELECT COUNT(DISTINCT interest_id) AS "in_metrics_but_not_in_mapping" 
FROM [fresh_segments].[interest_metrics]
WHERE interest_id NOT IN (
	SELECT id 
	FROM [fresh_segments].[interest_map]
);
GO

-- opposite case of given case
SELECT COUNT(id) AS "in_mapping_but_not_in_metrics" 
FROM [fresh_segments].[interest_map]
WHERE id NOT IN (
	SELECT DISTINCT interest_id 
	FROM [fresh_segments].[interest_metrics] 
	WHERE interest_id IS NOT NULL
);
GO




---> 5) Summarise the id values in the fresh_segments.interest_map by its total record count in this table
SELECT 
	COUNT(DISTINCT id) AS "record_count"
FROM [fresh_segments].[interest_map];
GO




---> 6) What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns 
---		from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.

--- Ans. If we want to check for all id of interest_map then we can use left, right or full join
---		 If we want to check for all interest_id of interest_metrics then we can use inner join
SELECT 
	met.*,
	interest_name,
	interest_summary,
	created_at,
	last_modified
FROM [fresh_segments].[interest_metrics] met
FULL JOIN [fresh_segments].[interest_map] map
	ON met.interest_id = map.id
WHERE interest_id = 21246;
GO




---> 7) Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?

--- Ans. Yes, there are total 188 records in joined table where the month_year value is before the created_at value
---		 It is so because we explicitly changed month_year value to date (month start date).
---		 This shouldn't be allowed. But if we only want to analyse on monthly basis then this changes will have no effect until and unless we go for daily analysis.
SELECT 
	met.*,
	interest_name,
	interest_summary,
	created_at,
	last_modified
FROM [fresh_segments].[interest_metrics] met
JOIN [fresh_segments].[interest_map] map
	ON met.interest_id = map.id
WHERE month_year < created_at 
	-- AND DATEPART(MONTH, month_year) <> DATEPART(MONTH, created_at);
GO



















---------------------------------------------------------------------------------------------> Interest Analysis <---------------------------------------------------------------------------------------------
---> 1) Which interests have been present in all month_year dates in our dataset?
SELECT
	interest_name
FROM [fresh_segments].[interest_metrics] met
JOIN [fresh_segments].[interest_map] map
	ON met.interest_id = map.id
GROUP BY interest_name
HAVING 
	COUNT(DISTINCT month_year) = (SELECT COUNT(DISTINCT month_year) FROM [fresh_segments].[interest_metrics])
ORDER BY interest_name;
GO





---> 2) Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
WITH total_months_cte AS (
	SELECT
		interest_id,
		COUNT(DISTINCT month_year) AS "month_year_frequency"
	FROM [fresh_segments].[interest_metrics]
	WHERE interest_id IS NOT NULL
	GROUP BY interest_id
),
cum_perc_cte AS (
	SELECT
		month_year_frequency,
		COUNT(interest_id) AS "different_interest",
		--SUM(COUNT(interest_id)) OVER(ORDER BY month_year_frequency DESC) AS "cummulative sum",
		--SUM(COUNT(interest_id)) OVER() AS "total_sum",
		ROUND(
			(SUM(COUNT(interest_id)) OVER(ORDER BY month_year_frequency DESC) / CAST(SUM(COUNT(interest_id)) OVER() AS REAL)) * 100, 
			2
		) AS "cummulative_percentage"
	FROM total_months_cte
	GROUP BY month_year_frequency
)
SELECT
	COUNT(*) AS "total_months"
FROM cum_perc_cte
WHERE cummulative_percentage > 90;
GO


-- starting from 14th month_year
WITH cum_perc_cte AS (
	SELECT
		month_year,
		COUNT(month_year) AS "total_interest_id",
		SUM(COUNT(interest_id)) OVER(ORDER BY month_year DESC) AS "cummulative sum",
		SUM(COUNT(interest_id)) OVER() AS "total_sum",
		ROUND((SUM(COUNT(interest_id)) OVER(ORDER BY month_year DESC) / CAST(SUM(COUNT(interest_id)) OVER() AS REAL)) * 100, 2) AS "cummulative_percentage"
	FROM [fresh_segments].[interest_metrics]
	WHERE month_year IS NOT NULL
	GROUP BY month_year
)
SELECT
	COUNT(*) AS "total_months"
FROM cum_perc_cte
WHERE cummulative_percentage > 90;
GO






---> 3) If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?

-- 598 ---- for less than equal to 6
-- 400 ---- for less than 6
SELECT 
	COUNT(*) AS "total_records"
FROM [fresh_segments].[interest_metrics]
WHERE interest_id IN (
	SELECT
		interest_id
	FROM [fresh_segments].[interest_metrics]
	GROUP BY interest_id
	HAVING 
		COUNT(DISTINCT month_year) < 6
);
GO





---> 4) Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your 
----	arguments - think about what it means to have less months present from a segment perspective.

-- Ans. According to me, for only given data analysis removing these data point would help in proper analysing but I wouldn't recommend removing it permanently because these interest_id 
--		may change as new records get inserted in future.




---> 5) After removing these interests - how many unique interests are there for each month?

WITH cte_total_months AS (
	SELECT interest_id,
		count(DISTINCT month_year) AS total_months
	FROM fresh_segments.interest_metrics
	GROUP BY interest_id
	HAVING count(DISTINCT month_year) >= 6
)
SELECT month_year,
	count(interest_id) AS n_interests
FROM fresh_segments.interest_metrics
WHERE interest_id IN (
		SELECT interest_id
		FROM cte_total_months
	) 
	AND month_year IS NOT NULL
GROUP BY month_year
ORDER BY month_year;
GO



















---------------------------------------------------------------------------------------------> Segment Analysis <---------------------------------------------------------------------------------------------
---> 1) Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? 
----	Only use the maximum composition value for each interest but you must keep the corresponding month_year
SELECT 
	*
INTO [fresh_segments].[filtered_interest_metrics]
FROM [fresh_segments].[interest_metrics]
WHERE interest_id IN (
	SELECT
		interest_id
	FROM [fresh_segments].[interest_metrics]
	GROUP BY interest_id
	HAVING 
		COUNT(DISTINCT month_year) >=6
);
GO




WITH composition_ranking_cte AS (
	SELECT 
		interest_id,
		month_year,
		composition,
		index_value,
		RANK() OVER(PARTITION BY month_year ORDER BY composition DESC) AS "max_to_min_ranking",
		RANK() OVER(PARTITION BY month_year ORDER BY composition) AS "min_to_max_ranking"
	FROM [fresh_segments].[filtered_interest_metrics]
	WHERE month_year IS NOT NULL
)
SELECt
	*
FROM composition_ranking_cte
WHERE max_to_min_ranking <= 10 OR min_to_max_ranking <=10
ORDER BY month_year, composition DESC
GO





---> 2) Which 5 interests had the lowest average ranking value?
SELECT TOP 5
	interest_name,
	ROUND(AVG(CAST(ranking AS REAL)), 2) AS "avg_ranking"
FROM [fresh_segments].[filtered_interest_metrics] met
JOIN [fresh_segments].[interest_map] map
	ON met.interest_id = map.id
GROUP BY interest_name
ORDER BY avg_ranking DESC;
GO




---> 3) Which 5 interests had the largest standard deviation in their percentile_ranking value?
SELECT TOP 5
	interest_id,
	interest_name,
	ROUND(AVG(percentile_ranking), 2) AS "avg_perc_rank",
	ROUND(
		STDEV(percentile_ranking),
		2
	) AS "std_dev"
FROM [fresh_segments].[filtered_interest_metrics] met
JOIN [fresh_segments].[interest_map] map
	ON met.interest_id = map.id
WHERE month_year IS NOT NULL
GROUP BY interest_id, interest_name
ORDER BY std_dev DESC
GO





---> 4) For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening 
---		for these 5 interests?
SELECT TOP 5
	interest_id,
	interest_name,
	MIN(percentile_ranking) AS "min_perc_rank",
	MAX(percentile_ranking) AS "max_perc_rank"
FROM [fresh_segments].[filtered_interest_metrics] met
JOIN [fresh_segments].[interest_map] map
	ON met.interest_id = map.id
WHERE interest_id IN (
	SELECT TOP 5
		interest_id
	FROM [fresh_segments].[filtered_interest_metrics] 
	WHERE month_year IS NOT NULL
	GROUP BY interest_id
	ORDER BY STDEV(percentile_ranking) DESC
)
GROUP BY interest_id, interest_name;
GO





---> 5) How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?

-- Ans. Most of the customer enjoy outing. Try to recommend customer based on their past interest and in general company can recommend outing related services and product
GO



















---------------------------------------------------------------------------------------------> Index Analysis <---------------------------------------------------------------------------------------------
----The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.

----Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.

---> 1) What is the top 10 interests by the average composition for each month?
WITH avg_composition_cte AS (
	SELECT 
		month_year,
		interest_id, 
		interest_name, 
		composition,
		index_value,
		ROUND(composition/index_value, 2) AS "avg_composition",
		DENSE_RANK() OVER(PARTITION BY month_year ORDER BY ROUND(composition/index_value, 2) DESC) AS "rank_no"
	FROM [fresh_segments].[interest_metrics] met
	JOIN [fresh_segments].[interest_map] map
		ON met.interest_id = map.id
	WHERE month_year IS NOT NULL
)
SELECT 
	*
FROM avg_composition_cte
WHERE rank_no<=10;
GO





---> 2) For all of these top 10 interests - which interest appears the most often?
WITH avg_composition_cte AS (
	SELECT 
		*, 
		ROUND(composition/index_value, 2) AS "avg_composition",
		DENSE_RANK() OVER(PARTITION BY month_year ORDER BY ROUND(composition/index_value, 2) DESC) AS "rank_no"
	FROM [fresh_segments].[interest_metrics]
	WHERE month_year IS NOT NULL
),
top_ten_cte AS (
	SELECT 
		*
	FROM avg_composition_cte
	WHERE rank_no<=10
),
common_interest_ranking_cte AS (
	SELECT
		interest_id,
		COUNT(interest_id) AS "frequency",
		RANK() OVER(ORDER BY COUNT(interest_id) DESC) AS "rank"
	FROM top_ten_cte
	GROUP BY interest_id
)
SELECT
	interest_name
FROM common_interest_ranking_cte cir
JOIN [fresh_segments].[interest_map] map
	ON cir.interest_id = map.id
WHERE [rank]=1;
GO




---> 3) What is the average of the average composition for the top 10 interests for each month?
WITH avg_composition_cte AS (
	SELECT 
		*, 
		ROUND(composition/index_value, 2) AS "avg_composition",
		RANK() OVER(PARTITION BY month_year ORDER BY ROUND(composition/index_value, 2) DESC) AS "rank_no"
	FROM [fresh_segments].[interest_metrics]
	WHERE month_year IS NOT NULL
),
top_ten_cte AS (
	SELECT 
		*
	FROM avg_composition_cte
	WHERE rank_no<=10
)
SELECT
	month_year,
	ROUND(AVG(avg_composition), 2) AS "avg"
FROM top_ten_cte
GROUP BY month_year;
GO




---> 4) What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.

----month_year				interest_name				max_index_composition		3_month_moving_avg					1_month_ago								2_months_ago

----2018-09-01		Work Comes First Travelers					8.26					7.61					Las Vegas Trip Planners: 7.21			Las Vegas Trip Planners: 7.36
----2018-10-01		Work Comes First Travelers					9.14					8.20					Work Comes First Travelers: 8.26		Las Vegas Trip Planners: 7.21
----2018-11-01		Work Comes First Travelers					8.28					8.56					Work Comes First Travelers: 9.14		Work Comes First Travelers: 8.26
----2018-12-01		Work Comes First Travelers					8.31					8.58					Work Comes First Travelers: 8.28		Work Comes First Travelers: 9.14
----2019-01-01		Work Comes First Travelers					7.66					8.08					Work Comes First Travelers: 8.31		Work Comes First Travelers: 8.28
----2019-02-01		Work Comes First Travelers					7.66					7.88					Work Comes First Travelers: 7.66		Work Comes First Travelers: 8.31
----2019-03-01		Alabama Trip Planners						6.54					7.29					Work Comes First Travelers: 7.66		Work Comes First Travelers: 7.66
----2019-04-01		Solar Energy Researchers					6.28					6.83					Alabama Trip Planners: 6.54				Work Comes First Travelers: 7.66
----2019-05-01		Readers of Honduran Content					4.41					5.74					Solar Energy Researchers: 6.28			Alabama Trip Planners: 6.54
----2019-06-01		Las Vegas Trip Planners						2.77					4.49					Readers of Honduran Content: 4.41		Solar Energy Researchers: 6.28
----2019-07-01		Las Vegas Trip Planners						2.82					3.33					Las Vegas Trip Planners: 2.77			Readers of Honduran Content: 4.41
----2019-08-01		Cosmetics and Beauty Shoppers				2.73					2.77					Las Vegas Trip Planners: 2.82			Las Vegas Trip Planners: 2.77
WITH avg_composition_cte AS (
	SELECT 
		month_year,
		interest_id, 
		ROUND(composition/index_value, 2) AS "avg_composition",
		DENSE_RANK() OVER(PARTITION BY month_year ORDER BY ROUND(composition/index_value, 2) DESC) AS "rank_no"
	FROM [fresh_segments].[interest_metrics]
	WHERE month_year IS NOT NULL
),
top_1_cte AS (
	SELECT 
		month_year,
		interest_name, 
		avg_composition,
		LAG(interest_name, 1) OVER(ORDER BY month_year) AS "1_month_ago_int",
		LAG(avg_composition, 1) OVER(ORDER BY month_year) AS "1_month_ago_max",
		LAG(interest_name, 2) OVER(ORDER BY month_year) AS "2_month_ago_int",
		LAG(avg_composition, 2) OVER(ORDER BY month_year) AS "2_month_ago_max"
	FROM avg_composition_cte acc
	JOIN [fresh_segments].[interest_map] mp
		ON acc.interest_id = mp.id
	WHERE rank_no=1
)
SELECT
	month_year,
	interest_name,
	avg_composition AS "max_index_composition",
	ROUND((avg_composition + [1_month_ago_max] + [2_month_ago_max]) / 3.0, 2) AS "3_month_moving_avg",
	[1_month_ago_int] + ': ' + CAST([1_month_ago_max] AS VARCHAR(60)) AS "1_month_ago",
	[2_month_ago_int] + ': ' + CAST([2_month_ago_max] AS VARCHAR(60)) AS "2_month_ago"
FROM top_1_cte;
GO




---> 5) Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?

-- Ans. According to me, in general, people's plan and interest depends on season and environment.
GO