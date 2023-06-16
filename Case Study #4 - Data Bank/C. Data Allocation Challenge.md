# 🏦 Case Study #4 - Data Bank
## 🧑‍💻 C. Data Allocation Challenge

To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

* Option 1: data is allocated based off the amount of money at the end of the previous month
* Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
* Option 3: data is updated real-time

For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

* running customer balance column that includes the impact each transaction
* customer balance at the end of each month
* minimum, average and maximum values of the running balance for each customer

Using all of the data available - how much data would have been required for each option on a monthly basis?

###### SQL

```TSQL
WITH cte AS (
  SELECT 
    customer_id,
    txn_date,
    txn_type,
    txn_amount,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY txn_date) transaction_order,
    (CASE WHEN txn_type IN ('withdrawal', 'purchase') THEN -txn_amount
     ELSE txn_amount END) plus_minus
  FROM customer_transactions
  GROUP BY customer_id, txn_date, txn_type, txn_amount)
  
  SELECT 
    *,
    (CASE WHEN ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY txn_date)=1 THEN SUM(CASE WHEN txn_type IN ('withdrawal', 'purchase') THEN -txn_amount ELSE txn_amount END) 
     ELSE (SUM(plus_minus) OVER (PARTITION BY customer_id ORDER BY txn_date ASC rows between unbounded preceding and current row))END) balance
  INTO impact_tbl
  FROM cte
  GROUP BY customer_id, txn_date, txn_type, txn_amount, plus_minus, transaction_order;
  
  
  SELECT *
  FROM impact_tbl;
```

###### Python

```python
df=tr

df['plus_minus'] = np.where(df['txn_type']=='deposit', df.txn_amount, (df.txn_amount*-1))

df['txn_order'] = df.sort_values(['customer_id', 'txn_date'], ascending=True)\
                          .groupby('customer_id')['txn_date'].rank(method='first').astype(int)

df['impact'] = df.sort_values(['customer_id', 'txn_date'], ascending=True).groupby(['customer_id'])['plus_minus'].cumsum()

result=df[['customer_id', 'txn_date', 'txn_type', 'txn_amount', 'txn_order', 'plus_minus', 'impact']]

result.sort_values(['customer_id', 'txn_date'], ascending=True)
```

First 5 rows.

| customer_id | txn_date   | txn_type | txn_amount | transaction_order | plus_minus | balance |
|-------------|------------|----------|------------|-------------------|------------|---------|
| 1	           | 2020-01-02 | deposit  | 	312        | 1                 | 312        | 312     |
| 1	           | 2020-03-05 | purchase | 	612        | 2                 | -612       | -300    |
| 1	           | 2020-03-17 | deposit  | 	324        | 3                 | 324        | 24      |
| 1	           | 2020-03-19 | purchase | 	664        | 4                 | -664       | -640    |
| 2	           | 2020-01-03 | deposit  | 	549        | 1                 | 549        | 549     |
  
###### Python

```python
result.groupby('customer_id').agg({'impact':['mean', 'max', 'min']})
```
 
First 5 rows. 
 
| customer_id | mean    | max  | min   |
|-------------|---------|------|-------|
| 1           | -151.00 | 312  | -640  |
| 2           | 579.50  | 610  | 549   |
| 3           | -732.40 | 144  | -1222 |
| 4           | 653.66  | 848  | 458   |
| 5           | -71.81  | 1780 | -2413 |
