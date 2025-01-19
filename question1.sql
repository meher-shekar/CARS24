-- Write a query to return Territory and corresponding Sales Growth.
-- Compare growth between periods Q4-2021 vs Q3-2021. If Territory (say T123) has Sales worth 100 in Q3-2021 and Sales worth 110 in Q4-2021,
-- then the Sales Growth will be 10% [ i.e. = ((110 - 100)/100) * 100 ] Output the ID of the Territory and the Sales Growth.
-- Only output these territories that had any sales in both quarters.

WITH sales_by_quarter AS (
SELECT
	mct.Territory_id,
	QUARTER(fcs.Order_date) AS Quarter,
	YEAR(fcs.Order_date) AS YEAR,
	SUM(fcs.Order_value) AS Total_sales
FROM
	cars24.fct_customer_sales fcs
INNER JOIN cars24.map_customer_territory mct ON
	fcs.Cust_id = mct.Cust_id
WHERE
	-- 	Condition to fetch only 3rd and 4th quarter
	QUARTER(fcs.Order_date) = 4
	OR QUARTER(fcs.Order_date) = 3
GROUP BY
	mct.Territory_id,
	QUARTER(fcs.Order_date),
	YEAR(fcs.Order_date)
),
-- CTE to calculate the 3rd and 4th quarter's sales data using the provided formula
sales_growth AS (
SELECT
	sq1.Territory_id,
	((sq1.Total_sales - sq2.Total_sales) * 100.0 / sq2.Total_sales) AS Sales_growth
FROM
	sales_by_quarter sq1
INNER JOIN 
        sales_by_quarter sq2
        ON
	sq1.Territory_id = sq2.Territory_id
	AND sq1.Quarter = 4
	AND sq2.Quarter = 3
	AND sq1.Year = sq2.Year
)
SELECT
	Territory_id,
	Sales_growth
FROM
	sales_growth
WHERE
	Sales_growth IS NOT NULL;