# 🥑 Case Study #3 - Foodie-Fi
## ❓ B. Data Analysis Questions
### 1. How many customers has Foodie-Fi ever had?

```TSQL
SELECT COUNT(DISTINCT customer_id)
FROM subscriptions;
```

| count | 
|-------------|
| 1000	           | 

---

### 2. What is the monthly distribution of `trial` plan `start_date` values for our dataset - use the start of the month as the group by value

```TSQL
SELECT EXTRACT(MONTH FROM start_date) month_by_month, COUNT(customer_id) n_of_customers
FROM subscriptions
WHERE plan_id=0
GROUP BY month_by_month
ORDER BY n_of_customers DESC;
```

First 5 rows.

| month_by_month | n_of_customers |
|----------------|----------------|
| 3              | 94             |
| 7              | 89             |
| 5              | 88             |
| 1              | 88             |
| 8              | 88             |

---

### 3. What plan `start_date` values occur after the year 2020 for our dataset? Show the breakdown by count of events for each `plan_name`

```TSQL
SELECT plan_name, COUNT(t1.plan_id) count_event
FROM subscriptions t1
JOIN plans t2 ON t1.plan_id = t2.plan_id
WHERE EXTRACT(YEAR FROM start_date) > 2020
GROUP BY plan_name
ORDER BY count_event DESC;
```

| plan_name     | count_event |
|---------------|-------------|
| churn         | 	71          |
| pro annual    | 	63          |
| pro monthly   | 	60          |
| basic monthly | 	8           |

---

### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

```TSQL
WITH cte AS (
   SELECT COUNT(DISTINCT customer_id) customer_count, CAST(COUNT(customer_id)AS NUMERIC) n_churn 
   FROM subscriptions
   WHERE plan_id=4 )

SELECT customer_count, ROUND((n_churn/1000)*100,1) perc_churned
FROM cte;
```

| customer_count     | perc_churned |
|---------------|-------------|
| 307         | 	30.7       |

---

### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

```TSQL
WITH ranking AS (
 SELECT s.customer_id, 
        s.plan_id, 
        p.plan_name, 
        ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.plan_id) AS plan_rank
 FROM subscriptions s
 JOIN plans p ON s.plan_id=p.plan_id
 )
 
 SELECT 
  COUNT(*) AS churn_count,
  ROUND(100*COUNT(*)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions),0) AS churn_percentage
 FROM ranking
 WHERE plan_id=4 AND plan_rank=2;
```

| churn_count     | churn_percentage |
|---------------|-------------|
| 92         | 	9       |

---

### 6. What is the number and percentage of customer plans after their initial free trial?

```TSQL
WITH ranking AS (
 SELECT s.customer_id, 
        s.plan_id, 
        p.plan_name, 
        ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.plan_id) AS plan_rank
 FROM subscriptions s
 JOIN plans p ON s.plan_id=p.plan_id
 )
 
 SELECT 
  COUNT(*) AS churn_count,
  ROUND(100*COUNT(*)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions),0) AS churn_percentage
 FROM ranking
 WHERE plan_id=4 AND plan_rank=2;
```

| plan_name     | n_customer | percentage |
|---------------|------------|------------|
| basic monthly | 546        | 54.6       |
| pro monthly   | 325        | 32.5       |
| churn         | 	92         | 9.2        |
| pro annual    | 	37         | 3.7        |

---

### 7. What is the customer count and percentage breakdown of all 5 `plan_name` values at `2020–12–31`?

```TSQL
WITH date_plan AS(
SELECT *,
       LEAD(start_date,1) OVER(PARTITION BY customer_id ORDER BY start_date)as next_date
FROM subscriptions
),

num_customer AS(
 SELECT plan_id,
        COUNT(DISTINCT customer_id)AS number_customer
 FROM date_plan
 WHERE (next_date IS NOT NULL AND ('2020-12-31'::DATE > start_date AND '2020-12-31'::DATE < next_date))
         OR (next_date IS NULL AND '2020-12-31'::DATE > start_date)
 GROUP BY 1
)

 SELECT plan_id,
  number_customer,
  ROUND(CAST(number_customer *100 / (SELECT COUNT(DISTINCT customer_id)as total_customer
       FROM subscriptions) AS NUMERIC),2)as pct_each_plan
 FROM num_customer;
```

| plan_id | number_customer | pct_each_plan |
|---------|-----------------|---------------|
| 0       | 19              | 1.00          |
| 1       | 224             | 22.00         |
| 2       | 326             | 32.00         |
| 3       | 195             | 19.00         |
| 4       | 235             | 23.00         |

---

### 8. How many customers have upgraded to an annual plan in 2020?

```TSQL
WITH cte AS(
   SELECT customer_id, plan_id, EXTRACT(YEAR FROM start_date::timestamp) yr
   FROM subscriptions
)
 
 SELECT COUNT(customer_id) n_customer
 FROM cte
 WHERE plan_id=3 AND yr='2020';
```

| n_customer | 
|---------|
| 195      | 

---

### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

```TSQL
 WITH start AS (
 SELECT customer_id, 
        MIN(start_date) day1
 FROM subscriptions
 GROUP BY customer_id
 ),
 
 upgrade_annual AS (
 SELECT customer_id, 
        start_date day_upgrade
 FROM subscriptions
 WHERE plan_id=3)
 
 SELECT ROUND(AVG(day_upgrade-day1),0) avg_days_to_upgrade
 FROM start s
 JOIN upgrade_annual u ON s.customer_id=u.customer_id;
```

| avg_days_to_upgrade | 
|---------|
| 105      | 

---

### 10. Can you further breakdown this average value into 30 day periods (i.e. 0–30 days, 31–60 days etc)

```TSQL
 --determine day 1 for each customer
 WITH start AS (
 SELECT customer_id, 
        MIN(start_date) day1
 FROM subscriptions
 GROUP BY customer_id
 ),
 
 --determine the day the customer upgraded to annual plan
 upgrade_annual AS (
 SELECT customer_id, 
        start_date day_upgrade
 FROM subscriptions
 WHERE plan_id=3),
 
 -- Sort values above in buckets of 12 with range of 30 days each
 bins AS (
  SELECT WIDTH_BUCKET(day_upgrade-day1, 0, 360, 12) AS day_bin
  FROM start s
  JOIN upgrade_annual u ON s.customer_id=u.customer_id) 
 
SELECT ((day_bin-1)*30 || ' - ' || (day_bin)*30) || ' days' AS breakdown,
       COUNT(*) AS customers
FROM bins
GROUP BY day_bin
ORDER BY day_bin;
```

First 5 rows.

| breakdown      | customers |
|----------------|-----------|
| 0 - 30 days    | 48        |
| 30 - 60 days   | 25        |
| 60 - 90 days   | 33        |
| 90 - 120 days  | 35        |
| 120 - 150 days | 43        |

`WIDTH_BUCKET` is a function that assigns values to buckets.

I added `customer_id` and `n_days_till_upgrade` (day_upgrade-day1) columns to CTE 'bins' to make it easier to understand, and the table looks like this. (First 5 rows)

| customer_id | n_days_till_upgrade | day_bin |
|-------------|---------------------|---------------------|
| 2           | 7                   | 1                   |
| 9           | 7                   | 1                   |
| 16          | 143                 | 5                   |
| 17          | 137                 | 5                   |
| 19          | 68                  | 3                   |

The first row means customer 2 took 7 days to upgrade to the `pro monthly` plan, and "7 days" fall in the #1 bin. 

---

### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

```TSQL
WITH lead_plan AS (
 SELECT 
	*, 
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date) AS row_n,
    LEAD(plan_id,1) OVER(PARTITION BY customer_id ORDER BY start_date) AS next_plan
 FROM subscriptions
 WHERE EXTRACT(YEAR FROM start_date)='2020'
 )
 
 SELECT COUNT(customer_id) n_customer
 FROM lead_plan
 WHERE plan_id=2 AND next_plan=1;
```

| n_customer      | 
|----------------|
|0    | 
