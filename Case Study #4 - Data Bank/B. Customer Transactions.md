# 🏦 Case Study #4 - Data Bank
## 💳 B. Customer Transactions
### 1. What is the unique count and total amount for each transaction type?

```TSQL
SELECT txn_type,
       COUNT(txn_type) n_transaction,
       SUM(txn_amount) total_transaction
FROM customer_transactions
GROUP BY txn_type;
```

| txn_type   | n_transaction | total_transaction |
|------------|---------------|-------------------|
| purchase   | 	1617          | 806537            |
| withdrawal | 	1580          | 793003            |
| deposit    | 	2671          | 1359168           |

---

### 2. What is the average total historical deposit counts and amounts for all customers?

```TSQL
WITH cte AS (
SELECT 
  customer_id,
  COUNT(txn_type) count_deposit,
  SUM(txn_amount) total_deposit
FROM customer_transactions
WHERE txn_type='deposit'
GROUP BY customer_id)

SELECT ROUND(AVG(count_deposit),1) avg_count_deposit,
       ROUND(AVG(total_deposit),1) avg_total_deposit
FROM cte;
```

| avg_count_deposit | avg_total_deposit |
|----------------|----------------|
| 5.3              | 2718.3             |

---

### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

```TSQL
WITH cte AS (
 SELECT customer_id,
        EXTRACT(MONTH FROM txn_date) month_n,
        SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) deposit_count,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) withdrawal_count,
        SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) purchase_count
  FROM customer_transactions
  GROUP BY month_n, customer_id
)

SELECT month_n, COUNT(customer_id) customer_count
FROM cte
WHERE deposit_count>1 AND (withdrawal_count=1 or purchase_count=1)
GROUP BY month_n;
```

| month_n | customer_count |
|----------------|----------------|
| 1              | 115             |
| 2              | 108             |
| 3              | 113             |
| 4              | 50             |

---

### 4. What is the closing balance for each customer at the end of the month?

```TSQL
--determine the last day of the months
--this doesn't include the month if the customer has no transaction
WITH txn_month AS (
 SELECT
	customer_id,
	STRING_AGG(DISTINCT(EXTRACT(MONTH FROM txn_date))::TEXT, ', ') n_month
 FROM customer_transactions
 GROUP BY customer_id
 ORDER BY customer_id),
 
--determine which month each customers are missing
missing_month AS (SELECT 
 txn_month.customer_id, 
  array(
    SELECT 
      unnest(ARRAY['1', '2', '3', '4']) 
      EXCEPT 
      SELECT 
        unnest(string_to_array(n_month, ', '))
    ) missing_months
FROM txn_month
ORDER BY 1)

--unnest missing_months column, and change to INT data type
SELECT 
 customer_id,
 CAST(UNNEST(missing_month.missing_months)AS INT) AS missing_month
INTO missing_months_tbl
FROM missing_month;

--add closing_balance column 
ALTER TABLE missing_months_tbl 
ADD closing_balance INT;

--add null to closing_balance column
INSERT INTO missing_months_tbl (closing_balance)
VALUES(NULL);

--'withdrawal', 'purchase' are negative and 'deposit' is positive amount
WITH txn AS (SELECT
    customer_id,
    date_trunc('month', txn_date) + interval '1 month' - interval '1 day' AS end_date,
    SUM(CASE WHEN txn_type IN ('withdrawal', 'purchase') THEN -txn_amount
             ELSE txn_amount END) AS transactions
  FROM customer_transactions
  GROUP BY customer_id, end_date
  ORDER BY customer_id, end_date),
   
  txn2 AS (
	  SELECT 
	    customer_id,
        end_date,
        SUM(transactions) OVER(PARTITION BY customer_id ORDER BY end_date ROWS UNBOUNDED PRECEDING) AS closing_balance
  FROM txn
  UNION ALL
  SELECT 
  customer_id, 
  CAST((CASE WHEN missing_month=1 THEN '2020-1-31'
             WHEN missing_month=2 THEN '2020-2-29'
             WHEN missing_month=3 THEN '2020-3-31'
             WHEN missing_month=4 THEN '2020-4-30'
       ELSE NULL END)AS DATE) end_date,
  closing_balance
FROM missing_months_tbl
ORDER BY customer_id, end_date),

txn3 AS (
SELECT
  customer_id,
  end_date,
  FIRST_VALUE(closing_balance) OVER(PARTITION BY value_partition ORDER BY customer_id, end_date) closing_balance
FROM (
	SELECT
		customer_id,
		end_date,
	   	closing_balance,
        SUM(CASE WHEN closing_balance IS NULL THEN 0 ELSE 1 END) OVER(ORDER BY customer_id, end_date) as value_partition
	FROM txn2
	ORDER BY customer_id, end_date) AS q)

SELECT * FROM txn3;
```

First 5 rows.

| customer_id | end_date   | closing_balance |
|-------------|------------|-----------------|
| 1	           | 2020-01-31 | 	312             |
| 1	           | 2020-02-29 | 	312             |
| 1	           | 2020-03-31 | 	-640            |
| 1	           | 2020-04-30 | 	-640            |
| 2	           | 2020-01-31 | 	549             |

> The last CTE part I referred to is this [answer](https://stackoverflow.com/a/19012333/17736130) on StackOverflow.
>
> Let's say that the customer doesn't have any transactions in February. 
> `FIRST VALUE()` and `LAG()` refer to the value on the value on `2020-01-31`, so it will work just fine. 
> But the problem is if the customer has a transaction in February but doesn't have a transaction in March then `FIRST VALUE()` refers to the January value so it'll be wrong.
> And also if the customer has no transaction in February and March `LAG()` only works for February but not March.
>
> In the `FROM` cause, the part I aliased as `value_partition` works like `IGNORE NULLS` (PostgreSQL doesn't support `IGNORE NULLS`) and fixes the problems above. 

---

### 5. What is the percentage of customers who increase their closing balance by more than 5%?

We are going to use the table from question 4 as `closing_balance_tbl`

```TSQL
DROP TABLE IF EXISTS april;
CREATE TEMP TABLE april AS (

WITH cte AS (SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY last_day) month_n
FROM closing_balance_tbl)

SELECT customer_id,
       closing_balance as april_closing
FROM cte
WHERE month_n=4);


DROP TABLE IF EXISTS january;
CREATE TEMP TABLE january AS (
  
  WITH cte AS (SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY last_day) month_n
FROM closing_balance_tbl)
  
SELECT customer_id,
       closing_balance as january_closing
FROM cte
WHERE month_n=1);

WITH cte AS (SELECT april.customer_id, january_closing, april_closing, ROUND(((april_closing-january_closing)/january_closing),1) increase
FROM april
LEFT JOIN january ON april.customer_id=january.customer_id)

SELECT ROUND(CAST(SUM(CASE WHEN increase > 5 THEN 1 ELSE 0 END)AS NUMERIC) / CAST(COUNT(customer_id)AS NUMERIC)*100,1) more_than_five_percent_increase
FROM cte;
```

| more_than_five_percent_increase | 
|-------------|
| 12.2      | 	

