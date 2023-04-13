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
WITH cte AS (SELECT
    customer_id,
    date_trunc('month', txn_date) + interval '1 month' - interval '1 day' AS end_date,
    SUM(CASE WHEN txn_type IN ('withdrawal', 'purchase') THEN -txn_amount
             ELSE txn_amount END) AS transactions
  FROM customer_transactions
  GROUP BY customer_id, end_date
  ORDER BY customer_id, end_date),
  
  cte2 AS 
  (SELECT customer_id,
          end_date,
          EXTRACT(MONTH FROM end_date) n_month,
          SUM(transactions) OVER(PARTITION BY customer_id ORDER BY end_date ROWS UNBOUNDED PRECEDING) AS closing_balance
  FROM cte),
  
  add_rows AS (
  SELECT 
    customer_id,
    string_agg(n_month::text, ', ') list_months
  FROM cte2
  GROUP BY customer_id
  ORDER BY customer_id
),

add_rows2 AS (SELECT 
  add_rows.customer_id, 
  array(
    SELECT 
      unnest(ARRAY['1', '2', '3', '4']) 
      EXCEPT 
      SELECT 
        unnest(string_to_array(list_months, ', '))
    ) missing_months
FROM add_rows
ORDER BY add_rows.customer_id)

SELECT 
 add_rows2.customer_id,
 CAST(n_month AS INT) n_month
INTO add_missing_months 
FROM add_rows2
CROSS JOIN UNNEST(add_rows2.missing_months) AS n_month (missing_months);

ALTER TABLE add_missing_months ADD closing_balance INT;

INSERT INTO add_missing_months (closing_balance)
VALUES(NULL);

WITH cte AS (SELECT
    customer_id,
    date_trunc('month', txn_date) + interval '1 month' - interval '1 day' AS end_date,
    SUM(CASE WHEN txn_type IN ('withdrawal', 'purchase') THEN -txn_amount
             ELSE txn_amount END) AS transactions
  FROM customer_transactions
  GROUP BY customer_id, end_date
  ORDER BY customer_id, end_date),
   
  cte2 AS (SELECT customer_id,
          EXTRACT(MONTH FROM end_date) n_month,
          SUM(transactions) OVER(PARTITION BY customer_id ORDER BY end_date ROWS UNBOUNDED PRECEDING) AS closing_balance
  FROM cte
  UNION ALL
  SELECT * 
  FROM add_missing_months
  ORDER BY customer_id, n_month),
  
cte3 AS (SELECT
  customer_id,
  CAST((CASE WHEN n_month=1 THEN '2020-1-31'
             WHEN n_month=2 THEN '2020-2-29'
             WHEN n_month=3 THEN '2020-3-31'
             WHEN n_month=4 THEN '2020-4-30'
       ELSE NULL END)AS DATE) last_day,
         n_month,
        (CASE WHEN closing_balance IS NULL 
              THEN LAG(COALESCE(closing_balance)) OVER(PARTITION BY customer_id ORDER BY n_month)
          ELSE closing_balance END) closing_balance
FROM cte2)

SELECT customer_id, last_day, 
       (CASE WHEN closing_balance IS NULL 
             THEN LAG(closing_balance) OVER(PARTITION BY customer_id ORDER BY n_month)
        ELSE closing_balance END) closing_balance
INTO closing_balance_tbl
FROM cte3;

SELECT * FROM closing_balance_tbl;
```

First 5 rows.

| customer_id | last_day   | closing_balance |
|-------------|------------|-----------------|
| 1	           | 2020-01-31 | 	312             |
| 1	           | 2020-02-29 | 	312             |
| 1	           | 2020-03-31 | 	-640            |
| 1	           | 2020-04-30 | 	-640            |
| 2	           | 2020-01-31 | 	549             |

---

### 5. What is the percentage of customers who increase their closing balance by more than 5%?

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

