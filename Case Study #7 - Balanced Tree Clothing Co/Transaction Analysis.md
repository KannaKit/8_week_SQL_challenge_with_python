# 🌄 Case Study #7 - Balanced Tree Clothing Co.
## 💳 Transaction Analysis
### 1. How many unique transactions were there?

```TSQL
SELECT COUNT(DISTINCT txn_id)
FROM sales;
```

| count  | 
|------------|
| 2500 |

---

### 2. What is the average unique products purchased in each transaction?

```TSQL
WITH cte AS (
SELECT txn_id, COUNT(DISTINCT prod_id) prod_count
FROM sales
GROUP BY txn_id)

SELECT ROUND(AVG(prod_count),2) avg_prod_count
FROM cte;
```

| avg_prod_count  | 
|------------|
| 6.04 |

---

### 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?

```TSQL
WITH cte AS (
SELECT txn_id, ROUND(SUM((price * qty) * (1 - discount::NUMERIC/100)),2) revenue
FROM sales
GROUP BY txn_id)

SELECT
  PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY revenue) twenty_fifth_percentile,
  PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY revenue) fifth_percentile,
  PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY revenue) seventy_fifth_percentile
FROM cte;
```

| twenty_fifth_percentile | fifth_percentile | seventy_fifth_percentile |
|-------------------------|------------------|--------------------------|
| 326.18                  | 441.00           | 572.75                   |

---

### 4. What is the average discount value per transaction?

```TSQL
WITH cte AS (
SELECT 
  txn_id, 
  ROUND(SUM((price*qty) * (discount::NUMERIC/100)),2) total_discount
FROM sales
GROUP BY txn_id)

SELECT ROUND(AVG(total_discount),2) avg_discount
FROM cte;
```

| avg_discount | 
|-------------------------|
| 62.49                  |

---

### 5. What is the percentage split of all transactions for members vs non-members?

```TSQL
WITH cte AS (
SELECT 
  member, CAST(COUNT(DISTINCT txn_id)AS NUMERIC) txn_count
FROM sales
GROUP BY member)

SELECT cte.member, ROUND(cte.txn_count/CAST(COUNT(DISTINCT sales.txn_id)AS NUMERIC)*100, 1) txn_percentage
FROM cte, sales
GROUP BY cte.member, cte.txn_count;
```

| member | txn_percentage |
|--------|----------------|
| false  | 39.8           |
| true   | 60.2           |

---

### 6. What is the average revenue for member transactions and non-member transactions?

```TSQL
WITH cte AS (
SELECT 
  member, txn_id, ROUND(SUM((price * qty) * (1 - discount::NUMERIC/100)),2) revenue_per_txn
FROM sales
GROUP BY 2,1)

SELECT
 member, 
 AVG(revenue_per_txn) avg_revenue
FROM cte
GROUP BY member;
```

| member | avg_revenue          |
|--------|----------------------|
| false  | 452.0077688442211055 |
| true   | 454.1369634551495017 |
