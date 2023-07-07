# 🌄 Case Study #7 - Balanced Tree Clothing Co.
## 💳 Transaction Analysis
### 1. How many unique transactions were there?
###### SQL

```TSQL
SELECT COUNT(DISTINCT txn_id)
FROM sales;
```

###### Python

```python
sales['txn_id'].nunique()
```

| count  | 
|------------|
| 2500 |

---

### 2. What is the average unique products purchased in each transaction?
###### SQL

```TSQL
WITH cte AS (
SELECT txn_id, COUNT(DISTINCT prod_id) prod_count
FROM sales
GROUP BY txn_id)

SELECT ROUND(AVG(prod_count),2) avg_prod_count
FROM cte;
```

###### Python

```python
sales.groupby('txn_id')['prod_id'].nunique().mean()
```

| avg_prod_count  | 
|------------|
| 6.04 |

---

### 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
###### SQL

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

###### Python

```python
df=sales
df['revenue_discounted'] = df.price*df.qty*(1-df.discount/100)
df=df.groupby('txn_id', as_index=False)['revenue_discounted'].sum()

q25 = df.sort_values('revenue_discounted', ascending=True)['revenue_discounted'].quantile(.25).round(2)
median = df['revenue_discounted'].quantile(.5).round(2)
q75 = df['revenue_discounted'].quantile(.75).round(2)

data={'percentile':['25%', '50%', '75%'],
    'number':[q25, median, q75]}

df = pd.DataFrame(data)

df
```

| twenty_fifth_percentile | fifth_percentile | seventy_fifth_percentile |
|-------------------------|------------------|--------------------------|
| 326.18                  | 441.00           | 572.75                   |

---

### 4. What is the average discount value per transaction?
###### SQL

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

###### Python

```python
df=sales

df['discounted'] = df.price*df.qty*(df.discount/100)

df=df.groupby('txn_id', as_index=False)['discounted'].sum()

df.discounted.mean()
```

| avg_discount | 
|-------------------------|
| 62.49                  |

---

### 5. What is the percentage split of all transactions for members vs non-members?
###### SQL

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

###### Python

```python
df = sales

df = df.groupby('member', as_index=False)['txn_id'].nunique()

df['percentage'] = 100*df.txn_id/df.txn_id.sum()

df
```

| member | txn_percentage |
|--------|----------------|
| false  | 39.8           |
| true   | 60.2           |

---

### 6. What is the average revenue for member transactions and non-member transactions?
###### SQL

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

###### Python

```python
df=sales

df['revenue_discounted'] = df.price*df.qty*(1-df.discount/100)

df = df.groupby(['txn_id', 'member'], as_index=False)['revenue_discounted'].sum()

df.groupby(['member'], as_index=False)['revenue_discounted'].mean()
```

| member | avg_revenue          |
|--------|----------------------|
| false  | 452.0077688442211055 |
| true   | 454.1369634551495017 |
