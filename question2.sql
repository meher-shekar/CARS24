-- Definition of Frequent Customer: A Customer who has transacts on the platform at least once in every 5 days since last transaction.

CREATE TABLE SALES (
	ORDER_ID INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	CUSTOMER_ID INT,
	ORDER_VALUE NUMERIC(10,2),
	ORDER_DATE DATETIME
);

INSERT INTO
    SALES (ORDER_ID, CUSTOMER_ID, ORDER_VALUE, ORDER_DATE)
VALUES
    (10001, 90001, 10000, '2022-02-01 09.00.00'),
    (10002, 90001, 10000, '2022-02-03 09.00.00'),
    (10003, 90001, 10000, '2022-02-07 09.00.00'),
    (10004, 90001, 20000, '2022-02-09 09.00.00'),
    (10005, 90001, 20000, '2022-02-14 09.00.00'),
    (10006, 90001, 10000, '2022-02-14 09.00.00'),
    (10007, 90001, 10000, '2022-02-17 09.00.00'),
    (10009, 90001, 80000, '2022-02-21 09.00.00'),
    (100020, 90001, 10000, '2022-02-23 09.00.00'),
    (100021, 90001, 10000, '2022-02-28 09.00.00'),
    (10010, 90002, 10000, '2022-02-01 09.00.00'),
    (10013, 90002, 30000, '2022-02-09 09.00.00'),
    (10014, 90002, 10000, '2022-02-14 09.00.00'),
    (10015, 90002, 10000, '2022-02-14 09.00.00'),
    (10016, 90002, 70000, '2022-02-17 09.00.00'),
    (10017, 90002, 10000, '2022-02-21 09.00.00'),
    (10019, 90002, 10000, '2022-02-28 09.00.00');

-- Write a SQL query for below questions:
-- Find which customers are Frequent.
-- Using partition by clause to find days difference between 2 purchases.
WITH customer_days_diff AS (
SELECT
	CUSTOMER_ID,
	DATEDIFF(ORDER_DATE, LAG(ORDER_DATE) OVER (PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE)) AS days_diff
FROM
	SALES
    )
    SELECT
	CUSTOMER_ID
FROM
	customer_days_diff
GROUP BY
	CUSTOMER_ID
	-- Condition to filter the customer who doesn't make a purchase in last 5 days
HAVING
	MAX(days_diff) <= 5;

-- Evaluate cumulative sum of ORDER_VALUE for each customer in ascending order of ORDER_DATE.
    
SELECT
	ORDER_ID,
	CUSTOMER_ID,
	ORDER_VALUE,
	DATE(ORDER_DATE) AS ORDER_DATE,
	SUM(ORDER_VALUE) OVER (
            PARTITION BY CUSTOMER_ID
ORDER BY
	ORDER_DATE
        ) AS CUMULATIVE_ORDER_VALUE
FROM
	SALES
ORDER BY
	CUSTOMER_ID,
	ORDER_DATE;


-- Order IDs which constitute Top 80 percentile basis Order_Value.

WITH RankedOrders AS (
SELECT
	ORDER_ID,
	PERCENT_RANK() OVER (
ORDER BY
	ORDER_VALUE ASC) AS PERCENTILE_RANK
FROM
	SALES
    )
    SELECT
	ORDER_ID
FROM
	RankedOrders
WHERE
	PERCENTILE_RANK >= 0.8;



-- Create a coupon_flag which becomes active on alternate transactions, signifying availability of coupon. Assume coupon_flag is 1 (Active) on first transaction, find number of days an offer was valid for each customer.
-- Case 1: considering coupon is used in first transaction so it will be inactive till next transaction and on 2nd transaction customer will again get a valid coupon to use it for next transaction.

WITH coupon_flags AS (
SELECT
	ORDER_ID,
	CUSTOMER_ID,
	date(ORDER_DATE) AS ORDER_DATE,
	CASE
		WHEN ROW_NUMBER() OVER ( PARTITION BY CUSTOMER_ID
	ORDER BY
		ORDER_DATE ) % 2 = 1 THEN 1
		ELSE 0
	END AS coupon_flag,
	datediff(ORDER_DATE, LAG(ORDER_DATE) OVER (PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE)) AS coupon_active_days
FROM
	SALES)
            SELECT
	CUSTOMER_ID,
	SUM(coupon_active_days) AS coupon_active_days
FROM
	coupon_flags
WHERE
	coupon_flag = 0
GROUP BY
	customer_id;


-- Case 2: considering coupon is generated in first transaction so it will be active till next transaction and on 2nd transaction coupon will be invalid.
WITH coupon_flags AS (
SELECT
	ORDER_ID,
	CUSTOMER_ID,
	date(ORDER_DATE) AS ORDER_DATE,
	CASE
		WHEN ROW_NUMBER() OVER ( PARTITION BY CUSTOMER_ID
	ORDER BY
		ORDER_DATE ) % 2 = 1 THEN 1
		ELSE 0
	END AS coupon_flag,
	datediff(ORDER_DATE, LAG(ORDER_DATE) OVER (PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE)) AS coupon_active_days
FROM
	SALES)
            SELECT
	CUSTOMER_ID,
	SUM(coupon_active_days) AS coupon_active_days
FROM
	coupon_flags
WHERE
	coupon_flag = 1
GROUP BY
	customer_id;