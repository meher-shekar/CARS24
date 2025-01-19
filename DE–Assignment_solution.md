**Que 1. Write a query to return Territory and corresponding Sales Growth. Compare growth between periods Q4-2021 vs Q3-2021. If Territory (say T123) has Sales worth 100 in Q3-2021 and Sales worth 110 in Q4-2021, then the Sales Growth will be 10% [ i.e. = ((110 - 100)/100) * 100 ] Output the ID of the Territory and the Sales Growth. Only output these territories that had any sales in both quarters.**

Table: fct_customer_sales
| Column | DataType |
| ---: | :--- |
| Cust_id | VARCHAR |
| Prod_sku_id | VARCHAR |
| Order_date | Datetime |
| Order_value | Int |
| Order_id | VARCHAR |

Table: map_customer_territory
| Column | DataType |
| ---: | :--- |
| Cust_id | VARCHAR |
| Territory_id | VARCHAR |

```SQL
-- CTE to fetch the year wise quarterly data for each Territory.
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
```

**Que 2. Definition of _**Frequent Customer**_: _A Customer who has transacts on the platform at least once in every 5 days since last transaction._**

```SQL
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
```
- **Write a SQL query for below questions:**
    - **Find which customers are Frequent.**
    ```SQL
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
    ```
    - **Evaluate cumulative sum of ORDER_VALUE for each customer in ascending order of ORDER_DATE.**
    ```SQL
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
    ```
    - **Order IDs which constitute Top 80 percentile basis Order_Value.**
    ```SQL
    WITH RankedOrders AS (
    SELECT
        ORDER_ID,
        PERCENT_RANK() OVER (
        ORDER BY ORDER_VALUE ASC) AS PERCENTILE_RANK
    FROM
        SALES
    )
    SELECT
        ORDER_ID
    FROM
        RankedOrders
    WHERE
        PERCENTILE_RANK >= 0.8;
    ```

    - **Create a coupon_flag which becomes active on alternate transactions, signifying availability of coupon. Assume coupon_flag is 1 (Active) on first transaction, find number of days an offer was valid for each customer.**
        - **Case 1:** _considering coupon is used in first transaction so it will be inactive till next transaction and on 2nd transaction customer will again get a valid coupon to use it for next transaction._
        ```SQL
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
        ```
        - **Case 2:** _considering coupon is generated in first transaction so it will be active till next transaction and on 2nd transaction coupon will be invalid._
        ```SQL
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
        ```

**Que 3. Consider the flight dataset attached. Write a Python code block to find all the travel options a passenger can take, along with flight details for the input Delhi (origin) to Mumbai (destination).**

**Imports**
```python
from collections import defaultdict, deque

import pandas as pd

# Inputs
origin = "Delhi"
destination = "Mumbai"

flights_df = pd.read_csv("./Flight Details.csv")
```

**Methods to calculate stops and time**
```python
def format_time(minutes):
    hours = minutes // 100
    mins = minutes % 100
    return f"{hours:02}:{mins:02}"

def calculate_total_duration(route):
    start_time = route[0]["StartTime"]
    end_time = route[-1]["EndTime"]
    duration = (end_time // 100 - start_time // 100) * 60 + (
        end_time % 100 - start_time % 100
    )
    return duration

def format_route(route):
    stops = len(route) - 1
    stop_details = (
        "Direct"
        if stops == 0
        else f"{stops} Stop(s) ({', '.join([f['Destination'] for f in route[:-1]])})"
    )
    total_duration = calculate_total_duration(route)
    return f"{route[0]['Origin'].strip()} - {route[-1]['Destination'].strip()} >> {total_duration // 60} hours {total_duration % 60} mins >> {stop_details}"

```
- **Using graph**
    ```Python
    def find_routes(origin, destination, flights):
        # Build a graph of routes
        graph = defaultdict(list)
        for _, row in flights.iterrows():
            graph[row["Origin"].strip()].append(
                {
                    "FlightNumber": row["FlightNumber"],
                    "Destination": row["Destination"].strip(),
                    "Origin": row["Origin"].strip(),
                    "StartTime": row["StartTime"],
                    "EndTime": row["EndTime"],
                }
            )

        results = []
        queue = deque([(origin, [], 0)])

        while queue:
            current_city, path, last_end_time = queue.popleft()
            if current_city == destination:
                results.append(path)
                continue

            for flight in graph[current_city]:
                if (
                    flight["StartTime"] >= last_end_time
                ):  # Check for valid connection timing
                    queue.append(
                        (flight["Destination"].strip(), path + [flight], flight["EndTime"])
                    )

        return results

    travel_options = find_routes(origin, destination, flights_df)

    # Display travel options
    if travel_options:
        for i, option in enumerate(travel_options, start=1):
            print(f"Option {i}:\n\t{format_route(option)}")
            for flight in option:
                print(
                    f"\tFlight {flight['FlightNumber']} from {flight['Origin'].strip()} to {flight['Destination'].strip()} ({format_time(flight['StartTime'])} - {format_time(flight['EndTime'])})"
                )
    else:
        print(f"No travel options available from {origin} to {destination}.")
    ```

- **Without using graph**
    ```python
    def find_travel_options(flights, origin, destination):
        flights = flights.to_dict(orient="records")
        results = []

        def find_routes(current_route, current_flight):
            # Add current flight to the route
            current_route.append(current_flight)

            # Check if we reached the destination
            if current_flight["Destination"].strip() == destination:
                results.append(list(current_route))
                current_route.pop()  # Backtrack for other options
                return

            # Find connecting flights
            for flight in flights:
                if (
                    flight["Origin"].strip() == current_flight["Destination"].strip()
                    and flight["StartTime"] > current_flight["EndTime"]
                ):
                    find_routes(current_route, flight)

            # Backtrack
            current_route.pop()

        # Find all starting flights from the origin
        for flight in flights:
            if flight["Origin"].strip() == origin:
                find_routes([], flight)

        return results

    # Get travel options
    travel_options = find_travel_options(flights_df, origin, destination)

    # Display travel options
    if travel_options:
        for i, option in enumerate(travel_options, start=1):
            print(f"Option {i}:\n\t{format_route(option)}")
            for flight in option:
                print(
                    f"\tFlight {flight['FlightNumber']} from {flight['Origin'].strip()} to {flight['Destination'].strip()} ({format_time(flight['StartTime'])} - {format_time(flight['EndTime'])})"
                )
    else:
        print(f"No travel options available from {origin} to {destination}.")
    ```

**Que 4. Write a python program to flatten a nested JSON to list all the available nic into dataframe. Use below JSON data for reference.**
```json
{
    "count": 13,
    "virtualmachine": [
        {
            "id": "1082e2ed-ff66-40b1-a41b-26061afd4a0b",
            "name": "test-2",
            "displayname": "test-2",
            "securitygroup": [
                {
                    "id": "9e649fbc-3e64-4395-9629-5e1215b34e58",
                    "name": "test",
                    "tags": []
                }
            ],
            "nic": [
                {
                    "id": "79568b14-b377-4d4f-b024-87dc22492b8e",
                    "networkid": "05c0e278-7ab4-4a6d-aa9c-3158620b6471"
                },
                {
                    "id": "3d7f2818-1f19-46e7-aa98-956526c5b1ad",
                    "networkid": "b4648cfd-0795-43fc-9e50-6ee9ddefc5bd",
                    "traffictype": "Guest"
                }
            ],
            "hypervisor": "KVM",
            "affinitygroup": [],
            "isdynamicallyscalable": false
        }
    ]
}
```

```python
# Normalize JSON data to extract NIC information along with other details
nic_df = pd.json_normalize(
    nested_json["virtualmachine"],
    record_path="nic",
    meta=[
        "id",
        "name",
        "displayname",
        "securitygroup",
        "hypervisor",
        "affinitygroup",
        "isdynamicallyscalable",
    ],
    meta_prefix="vm_",
).rename(
    columns={
        "id": "nic_id",
        "networkid": "nic_networkid",
        "traffictype": "nic_traffictype",
        "vm_id": "id",
        "vm_name": "name",
        "vm_displayname": "displayname",
        "vm_securitygroup": "securitygroup",
        "vm_hypervisor": "hypervisor",
        "vm_affinitygroup": "affinitygroup",
        "vm_isdynamicallyscalable": "isdynamicallyscalable",
    },
    inplace=True,
)
print(nic_df)
```

**Que 5. Design a compute resource for given problem statement. The Marketing team are running campaigns online and all the user experiences are captured via Google Analytics which is replicated into Google BigQuery.  The BI analyst has gathered all the sales history data into Snowflake data warehouse. How and where can the analyst combine these two datasets in order to identify possible leads for the business? You need to suggest a platform or compute instance where both the sources can be queried together and tables can be joined to find out recent sellers visiting the advertisements surfing through all the buying options.**


**Solution:**
We can design a solution using AWS Glue, Amazon S3, Amazon Redshift, Amazon Athena, and Amazon QuickSight. 

**Step 1: _Extract Data from Google BigQuery (Google BigQuery -> **Amazon S3)_
- Use AWS Glue to connect to Google BigQuery using JDBC and extract the user experience data.
- Configure AWS Glue Crawlers to catalog the schema of the extracted BigQuery data in the AWS Glue Data Catalog.
- Store the extracted data in Amazon S3 in a structured format.

**Step 2: _Extract Data from Snowflake (Snowflake -> Amazon S3)_**
- Use AWS Glue to connect to Snowflake using JDBC and extract the sales data.
- Similarly, use AWS Glue Crawlers to catalog the Snowflake data into the AWS Glue Data Catalog.
- Store the extracted Snowflake data in Amazon S3 in a structured format.

**Step 3: _Data Analysis and Combination_**

**Option 1:** _Amazon Redshift_
- Load the data stored in Amazon S3 into Amazon Redshift using the COPY command.
- Create tables or views in Redshift to join and analyze the data from both sources.
- Perform SQL queries in Redshift to generate insights in order to identify possible leads for the business.

**Option 2:** _Amazon Athena_
- Alternatively, we can use Amazon Athena to query the data directly from Amazon S3 without moving it to Redshift.
- Configure Athena tables using the schema stored in the AWS Glue Data Catalog.
- Write SQL queries in Athena to join the datasets to identify potential leads.
- This approach avoids the need for an additional data warehouse, making it cost-effective.

**Step 4: _Visualization and Reporting_**
- Use Amazon QuickSight to connect to either Amazon Redshift or Amazon Athena for creating visualizations and dashboards.
- we can build an interactive dashboards to present insights to stakeholders, enabling the Marketing team to track campaign performance and identify leads effectively.