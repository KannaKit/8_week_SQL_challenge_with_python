# 🥑 Case Study #3 - Foodie-Fi
## 💳 C. Challenge Payment Question

The Foodie-Fi team wants you to create a new `payments` table for the year 2020 that includes amounts paid by each customer in the `subscriptions` table with the following requirements:

* monthly payments always occur on the same day of month as the original `start_date` of any monthly paid plan
* upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
* upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
* once a customer churns they will no longer make payments

Example outputs for this table might look like the following (first 8 rows):

| customer_id | plan_id | plan_name     | payment_date | amount | payment_order |
|-------------|---------|---------------|--------------|--------|---------------|
| 1           | 1       | basic monthly | 2020-08-08   | 9.90   | 1             |
| 1           | 1       | basic monthly | 2020-09-08   | 9.90   | 2             |
| 1           | 1       | basic monthly | 2020-10-08   | 9.90   | 3             |
| 1           | 1       | basic monthly | 2020-11-08   | 9.90   | 4             |
| 1           | 1       | basic monthly | 2020-12-08   | 9.90   | 5             |
| 2           | 3       | pro annual    | 2020-09-27   | 199.00 | 1             |
| 13          | 1       | basic monthly | 2020-12-22   | 9.90   | 1             |
| 15          | 2       | pro monthly   | 2020-03-24   | 19.90  | 1             |

```TSQL
WITH cte AS (
 SELECT
  customer_id,
  t1.plan_id,
  t2.plan_name,
  start_date AS payment_date,
  --determine last payment date
  CASE
   WHEN LEAD(start_date) OVER (PARTITION BY t1.customer_id ORDER BY start_date) IS NULL THEN '2020-12-31'
  ELSE start_date + (interval '1 month' * (EXTRACT(MONTH FROM LEAD(start_date) OVER(PARTITION BY customer_id ORDER BY start_date))::int - EXTRACT(MONTH FROM start_date)::int)) END AS last_date,
  price AS amount
  FROM subscriptions t1
  JOIN plans t2 ON t1.plan_id = t2.plan_id
  --filter out 'trial' and data only in 2020 
  WHERE t1.plan_id != 0 AND EXTRACT(YEAR FROM start_date)=2020),
  
cte2 AS(

 SELECT
  customer_id,
  plan_id,
  plan_name,
  --increment payment_date by monthly
  (payment_date + make_interval(months => g.num))::date AS payment_date,
  --last_date - payment_date AS n_months
  last_date,
  amount
 FROM cte
 CROSS JOIN generate_series(0, (EXTRACT(MONTH FROM last_date)::INT-EXTRACT(MONTH FROM payment_date)::INT)) AS g(num)
 --stop incrementing when payment_date = last_date
 WHERE payment_date <= last_date AND plan_name != 'pro annual'
 ORDER BY payment_date)

 
 SELECT *
 INTO pre_tbl
 FROM cte
 UNION 
 SELECT *
 FROM cte2
 ORDER BY customer_id, payment_date;
 
 DROP TABLE IF EXISTS payments;
  WITH cte AS(
  SELECT 
   customer_id,
   plan_id,
   plan_name,
   payment_date,
   amount,
   ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY payment_date) AS payment_order,
   (CASE WHEN plan_id =4 THEN ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY payment_date)
    ELSE NULL END) AS churn_order,
   LAG(plan_id, 1) OVER(PARTITION BY customer_id) AS lag_plan_id
  FROM pre_tbl
 )
 
SELECT 
  cte.customer_id, 
  cte.plan_id, 
  cte.plan_name, 
  cte.payment_date,
  cte.payment_order,
  (CASE WHEN (plan_id = 2 OR plan_id = 3) AND LAG(plan_id) OVER(PARTITION BY customer_id ORDER BY payment_date) = 1 AND payment_date <= LEAD(payment_date) OVER(PARTITION BY customer_id ORDER BY payment_date) THEN amount-9.90
        WHEN plan_id = 3 AND (LAG(plan_id) OVER(PARTITION BY customer_id ORDER BY payment_date) = 2 OR LAG(plan_id) OVER(PARTITION BY customer_id ORDER BY payment_date) = 1) AND payment_date <= LEAD(payment_date) OVER(PARTITION BY customer_id ORDER BY payment_date) THEN amount-19.90
   ELSE amount END) AS amount
 INTO payments
 FROM cte
WHERE amount IS NOT NULL AND (lag_plan_id is null or lag_plan_id IN (1,2,3))
 --EXCEPT (SELECT cte2.customer_id, cte2.plan_id, cte2.plan_name, cte2.payment_date, cte2.amount, cte2.payment_order FROM cte2 WHERE churn_order2 != 1)
 ORDER BY customer_id, payment_date;
 
 --show first 20 lines
 select *
 from payments
  limit 20;
);
```
