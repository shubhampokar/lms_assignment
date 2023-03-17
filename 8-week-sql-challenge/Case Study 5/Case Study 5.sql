---------------------------------------------------------------------------------------------> 1. Data Cleansing Steps <---------------------------------------------------------------------------------------------
--In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

--Convert the week_date to a DATE format

--Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc

--Add a month_number with the calendar month for each week_date value as the 3rd column

--Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values

--Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value

--		segment		age_band
--			1		Young Adults
--			2		Middle Aged
--		3 or 4		Retirees

--Add a new demographic column using the following mapping for the first letter in the segment values:
--		segment		demographic
--			C		Couples
--			F		Families
--Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns

--Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

SELECT
	CONVERT(DATE, week_date, 3) AS "week_date",
	region,
	platform,
	DATEPART(WEEK, CONVERT(DATE, week_date, 3)) AS "week_no",
	DATEPART(MONTH, CONVERT(DATE, week_date, 3)) AS "month_no",
	DATEPART(YEAR, CONVERT(DATE, week_date, 3)) AS "year",
	CASE segment
		WHEN 'null' THEN 'Unknown'
		ELSE segment
	END AS "segment",
	CASE
		WHEN segment <> 'null' THEN
			CASE RIGHT(segment, 1)
				WHEN 1 THEN 'Young Adults'
				WHEN 2 THEN 'Middle Aged'
				WHEN 3 THEN 'Retirees'
				WHEN 4 THEN 'Retirees'
			END
		ELSE 'Unknown'
	END AS "age_band",
	CASE
		WHEN segment <> 'null' THEN
			CASE LEFT(segment, 1)
				WHEN 'C' THEN 'Couples'
				WHEN 'F' THEN 'Families'
			END
		ELSE 'Unknown'
	END AS "demographic",
	customer_type,
	transactions,
	sales,
	ROUND(sales / CAST(transactions AS REAL), 2) AS "avg_transaction"
INTO data_mart.clean_weekly_sales
FROM [data_mart].[weekly_sales];
GO



















---------------------------------------------------------------------------------------------> 2. Data Exploration <---------------------------------------------------------------------------------------------

---> 1) What day of the week is used for each week_date value?
SELECT 
	DISTINCT DATENAME(WEEKDAY, week_date) AS "week_day"
FROM [data_mart].[clean_weekly_sales];
GO





---> 2) What range of week numbers are missing from the dataset?
SELECT * FROM GENERATE_SERIES(1, 52)
EXCEPT
SELECT DISTINCT week_no
FROM [data_mart].[clean_weekly_sales];
GO





---> 3) How many total transactions were there for each year in the dataset?
SELECT 
	[year],
	SUM(transactions) AS "total_transactions"
FROM [data_mart].[clean_weekly_sales]
GROUP BY [year]
ORDER BY [year];
GO





---> 4) What is the total sales for each region for each month?

-- per each month
SELECT 
	region,
	month_no,
	SUM(CAST(sales AS REAL)) AS "total_transactions"
FROM [data_mart].[clean_weekly_sales]
GROUP BY region, month_no
ORDER BY region, month_no;
GO


-- per each month-year
SELECT 
	region,
	month_no,
	[year],
	SUM(CAST(sales AS REAL)) AS "total_transactions"
FROM [data_mart].[clean_weekly_sales]
GROUP BY region, month_no, [year]
ORDER BY region, month_no;
GO





---> 5) What is the total count of transactions for each platform
SELECT 
	[platform],
	SUM(transactions) AS "total_transactions"
FROM [data_mart].[clean_weekly_sales]
GROUP BY [platform]
ORDER BY [platform];
GO




---> 6) What is the percentage of sales for Retail vs Shopify for each month?

--- considering only months
WITH platform_sales_cte AS (
	SELECT
		[platform], 
		month_no,
		SUM(CAST(sales AS REAL)) AS "total_sales"
	FROM [data_mart].[clean_weekly_sales]
	GROUP BY [platform], month_no
)
SELECT 
  month_no, 
  ROUND(
    (
      SUM (
        CASE WHEN [platform] = 'Retail' THEN total_sales ELSE 0 END
      ) / SUM(total_sales)
    ) * 100, 
    2
  ) AS "retail (%)", 
  ROUND(
	  (
		SUM(
		  CASE WHEN [platform] = 'Shopify' THEN total_sales ELSE 0 END
		) / SUM(total_sales)
	  ) * 100,
	 2
  ) AS "shopify (%)" 
FROM 
  platform_sales_cte 
GROUP BY 
  month_no;
GO

--- rolling up year and month, sales percentage wrt overall sales, sales wrt particular year
SELECT 
	[platform], 
	month_no, 
	[year],
	ROUND(
		(
			SUM(CAST(sales AS REAL)) 
			/ 
			(SELECT SUM(CAST(sales AS REAL)) FROM [data_mart].[clean_weekly_sales])
		) 
		* 
		100, 
		2
	) AS "sales_per_month_year_wrt_overall_sales (%)",
	ROUND(
		(
			SUM(CAST(sales AS REAL)) 
			/ 
			(
				CASE [year]
					WHEN 2018 THEN (SELECT SUM(CAST(sales AS REAL)) FROM [data_mart].[clean_weekly_sales] WHERE [year] = 2018)
					WHEN 2019 THEN (SELECT SUM(CAST(sales AS REAL)) FROM [data_mart].[clean_weekly_sales] WHERE [year] = 2019)
					WHEN 2020 THEN (SELECT SUM(CAST(sales AS REAL)) FROM [data_mart].[clean_weekly_sales] WHERE [year] = 2020)
				END
			)
		) 
		* 
		100, 
		2
	) AS "sales_per_month_year_wrt_sales_per_year (%)"
FROM [data_mart].[clean_weekly_sales]
GROUP BY [platform], ROLLUP(month_no, [year])
ORDER BY [platform], month_no, [year];
GO






---> 7) What is the percentage of sales by demographic for each year in the dataset?
SELECT 
	demographic,  
	[year],
	ROUND(
		(
			SUM(CAST(sales AS REAL)) 
			/ 
			(SELECT SUM(CAST(sales AS REAL)) FROM [data_mart].[clean_weekly_sales])
		) 
		* 
		100, 
		2
	) AS "sales_per_month_year_wrt_overall_sales (%)",
	ROUND(
		(
			SUM(CAST(sales AS REAL)) 
			/ 
			(
				CASE [year]
					WHEN 2018 THEN (SELECT SUM(CAST(sales AS REAL)) FROM [data_mart].[clean_weekly_sales] WHERE [year] = 2018)
					WHEN 2019 THEN (SELECT SUM(CAST(sales AS REAL)) FROM [data_mart].[clean_weekly_sales] WHERE [year] = 2019)
					WHEN 2020 THEN (SELECT SUM(CAST(sales AS REAL)) FROM [data_mart].[clean_weekly_sales] WHERE [year] = 2020)
				END
			)
		) 
		* 
		100, 
		2
	) AS "sales_per_month_year_wrt_sales_per_year (%)"
FROM [data_mart].[clean_weekly_sales]
GROUP BY demographic, [year]
ORDER BY demographic, [year];
GO





---> 8) Which age_band and demographic values contribute the most to Retail sales?
--- among knwon age_band and demographic including unknown for all calculations
SELECT TOP 1
	age_band, 
	demographic,
	ROUND(
		(
			SUM(CAST(sales AS REAL)) 
			/ 
			(SELECT SUM(CAST(sales AS REAL)) FROM [data_mart].[clean_weekly_sales])
		) 
		* 
		100, 
		2
	) AS "sales_per_month_year_wrt_overall_sales (%)"
FROM [data_mart].[clean_weekly_sales]
WHERE [platform] = 'Retail'
GROUP BY age_band, demographic
ORDER BY "sales_per_month_year_wrt_overall_sales (%)" DESC;
GO


--- among knwon age_band and demographic excluding unknown for all calculations
SELECT TOP 1
	age_band, 
	demographic,
	ROUND(
		(
			SUM(CAST(sales AS REAL)) 
			/ 
			(SELECT SUM(CAST(sales AS REAL)) FROM [data_mart].[clean_weekly_sales] WHERE [platform] = 'Retail' AND age_band <> 'Unknown')
		) 
		* 
		100, 
		2
	) AS "sales_per_month_year_wrt_overall_sales (%)"
FROM [data_mart].[clean_weekly_sales]
WHERE [platform] = 'Retail' AND age_band <> 'Unknown'
GROUP BY age_band, demographic
ORDER BY "sales_per_month_year_wrt_overall_sales (%)" DESC;
GO





---> 9) Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

-- Ans. no we can't, if we want to then we need to find summation of sales per summation of transactions for each year as shown below...
SELECT
	[platform], 
	[year],
	ROUND(
		(
			SUM(CAST(sales AS REAL)) 
			/ 
			SUM(CAST(transactions AS REAL)) 
		), 
		2
	) AS "sales_per_transactions (avg_transaction_size)"
FROM [data_mart].[clean_weekly_sales]
GROUP BY [platform], [year]
ORDER BY [year], [platform];
GO



















---------------------------------------------------------------------------------------------> 3. Before & After Analysis <---------------------------------------------------------------------------------------------
--- This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
--- Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
--- We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
--- Using this analysis approach - answer the following questions:



---> 1) What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

-- method 1 -- relative cost: 50%
WITH sales_cte AS (
	SELECT
		SUM(
			CASE 
				WHEN week_date < '2020-06-15' THEN CAST(sales AS REAL)
				ELSE 0
			END
		) AS "before_sales",
		SUM(
			CASE 
				WHEN week_date >= '2020-06-15' THEN CAST(sales AS REAL)
				ELSE 0
			END
		) AS "after_sales"
	FROM [data_mart].[clean_weekly_sales]
	WHERE week_date BETWEEN DATEADD(WEEK, -4, '2020-06-15') AND DATEADD(DAY, -1, DATEADD(WEEK, 4, '2020-06-15'))
)
SELECT
	*,
	after_sales - before_sales AS "change_value",
	ROUND(((after_sales - before_sales) / before_sales) * 100, 2) AS "growth/reduction_rate (rate)"
FROM sales_cte;
GO

-- method 2 using week_no (less dynamic compare to method 1 as week_no is hard-coded)-- relative cost: 50%
-- getting week_no for base date
SELECT DISTINCT week_no
FROM [data_mart].[clean_weekly_sales]
WHERE week_date = '2020-06-15'
GO

WITH sales_cte AS (
	SELECT
		SUM(
			CASE 
				WHEN week_date < '2020-06-15' THEN CAST(sales AS REAL)
				ELSE 0
			END
		) AS "before_sales",
		SUM(
			CASE 
				WHEN week_date >= '2020-06-15' THEN CAST(sales AS REAL)
				ELSE 0
			END
		) AS "after_sales"
	FROM [data_mart].[clean_weekly_sales]
	WHERE week_no BETWEEN 21 AND 28 AND [year] = 2020
)
SELECT
	*,
	after_sales - before_sales AS "change_value",
	ROUND(((after_sales - before_sales) / before_sales) * 100, 2) AS "growth/reduction_rate (rate)"
FROM sales_cte;
GO





---> 2) What about the entire 12 weeks before and after?
WITH sales_cte AS (
	SELECT
		SUM(
			CASE 
				WHEN week_date < '2020-06-15' THEN CAST(sales AS REAL)
				ELSE 0
			END
		) AS "before_sales",
		SUM(
			CASE 
				WHEN week_date >= '2020-06-15' THEN CAST(sales AS REAL)
				ELSE 0
			END
		) AS "after_sales"
	FROM [data_mart].[clean_weekly_sales]
	WHERE week_date BETWEEN DATEADD(WEEK, -12, '2020-06-15') AND DATEADD(DAY, -1, DATEADD(WEEK, 12, '2020-06-15'))
)
SELECT
	*,
	after_sales - before_sales AS "change_value",
	ROUND(((after_sales - before_sales) / before_sales) * 100, 2) AS "growth/reduction_rate (%)"
FROM sales_cte;
GO




---> 3) How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

-- 12 week before after 15 June for each year
WITH sales_cte AS (
	SELECT
		[year],
		SUM(
			CASE 
				WHEN week_date BETWEEN DATEADD(WEEK, -12, CAST([year] AS VARCHAR(4))+'-06-15') AND DATEADD(DAY, -1, CAST([year] AS VARCHAR(4))+'-06-15') THEN CAST(sales AS REAL)
				ELSE 0
			END
		) AS "before_12_weeks_sales",
		SUM(
			CASE 
				WHEN week_date BETWEEN  CAST([year] AS VARCHAR(4))+'-06-15' AND DATEADD(DAY, -1, DATEADD(WEEK, 12, CAST([year] AS VARCHAR(4))+'-06-15')) THEN CAST(sales AS REAL)
				ELSE 0
			END
		) AS "after_12_weeks_sales"
	FROM [data_mart].[clean_weekly_sales]
	GROUP BY [year]
)
SELECT
	*,
	after_12_weeks_sales - before_12_weeks_sales AS "12_weeks_change_value",
	ROUND(
		(
			(after_12_weeks_sales - before_12_weeks_sales) / before_12_weeks_sales
		) * 100, 
		2
	) AS "growth/reduction_rate 12_weeks (rate)"
FROM sales_cte
ORDER BY [year];
GO

-- 4 week before after 15 June for each year
WITH sales_cte AS (
	SELECT
		[year],
		SUM(
			CASE 
				WHEN week_date BETWEEN DATEADD(WEEK, -4, CAST([year] AS VARCHAR(4))+'-06-15') AND DATEADD(DAY, -1, CAST([year] AS VARCHAR(4))+'-06-15') THEN CAST(sales AS REAL)
				ELSE 0
			END
		) AS "before_4_weeks_sales",
		SUM(
			CASE 
				WHEN week_date BETWEEN  CAST([year] AS VARCHAR(4))+'-06-15' AND DATEADD(DAY, -1, DATEADD(WEEK, 4, CAST([year] AS VARCHAR(4))+'-06-15')) THEN CAST(sales AS REAL)
				ELSE 0
			END
		) AS "after_4_weeks_sales"
	FROM [data_mart].[clean_weekly_sales]
	GROUP BY [year]
)
SELECT
	*,
	after_4_weeks_sales - before_4_weeks_sales AS "4_weeks_change_value",
	ROUND(
		(
			(after_4_weeks_sales - before_4_weeks_sales) / before_4_weeks_sales
		) * 100, 
		2
	) AS "growth/reduction_rate 4_weeks (rate)"
FROM sales_cte
ORDER BY [year];
GO






















---------------------------------------------------------------------------------------------> 4. Bonus Question <---------------------------------------------------------------------------------------------
---> Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
---		region
---		platform
---		age_band
---		demographic
---		customer_type

---> Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?

-- Ans.	Europe has highest negative as well as positive impact
--		south america has mostly negative impact
--		families are mostly under negative influence

WITH sales_cte AS (
	SELECT
		region, 
		[platform], 
		age_band, 
		demographic, 
		customer_type,
		SUM(
			CASE 
				WHEN week_date < '2020-06-15' THEN CAST(sales AS REAL)
				ELSE 0
			END
		) AS "before_sales",
		SUM(
			CASE 
				WHEN week_date >= '2020-06-15' THEN CAST(sales AS REAL)
				ELSE 0
			END
		) AS "after_sales"
	FROM [data_mart].[clean_weekly_sales]
	WHERE week_date BETWEEN DATEADD(WEEK, -12, '2020-06-15') AND DATEADD(DAY, -1, DATEADD(WEEK, 12, '2020-06-15'))
	GROUP BY region, [platform], age_band, demographic, customer_type
)
SELECT
	*,
	after_sales - before_sales AS "change_value",
	ROUND(((after_sales - before_sales) / before_sales) * 100, 2) AS "growth/reduction_rate (rate)"
FROM sales_cte
WHERE age_band <> 'Unknown'
ORDER BY [growth/reduction_rate (rate)];
GO