# 🏦 Case Study #4 - Data Bank
## 💪 D. Extra Challenge

Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.

If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?

Special notes:

* Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!

###### SQL

```TSQL
--using the table created for challenge C
WITH cte AS (SELECT *, LAG(txn_date) OVER(PARTITION BY customer_id ORDER BY txn_date) previous_txn
             FROM impact_tbl), 
--there's no previous trunsaction = it's the customer's first time using data bank
cte2 as 
 (SELECT *, 
        (CASE WHEN previous_txn is null THEN 1
         ELSE txn_date-previous_txn END) days_n
  FROM cte),
  
--calculate the daily interest rate, since the annual rate is 6% the daily rate will be 0.06/365
--if the balance is negative then no interest
--if it's the customer's first day using data bank then the customer gets (0.06/365)% interest
--if the customer kept their balance positive for 30 days then the customer will get 30*(0.06/365)% interest
interest_tbl AS
(SELECT 
  customer_id, 
  txn_date,
  txn_type,
  txn_amount,
  balance,
  transaction_order,
  days_n,
  (CASE WHEN LAG(balance) OVER(PARTITION BY customer_id ORDER BY txn_date) < 0 THEN 0 
        WHEN days_n = 1 THEN ROUND((0.06/365),2)
   ELSE ROUND((LAG(balance) OVER(PARTITION BY customer_id ORDER BY txn_date)*0.06/365*days_n),2) END) interest
FROM cte2
ORDER BY customer_id, transaction_order)

SELECT
  customer_id,
  txn_date,
  txn_type, 
  txn_amount,
  balance,
  balance+interest balance_inc_interest
FROM interest_tbl
LIMIT 25;
```

###### Python

```python
df = result

df['prev_txn'] = df.sort_values(['customer_id', 'txn_date'], ascending=True).groupby('customer_id')['txn_date'].shift(1)

df['day_n'] = np.where(df.prev_txn.isna(), 1, (df.txn_date-df.prev_txn).dt.days).astype(int)

daily_interest = 0.06/365

df['interest']=np.where(df.impact>0, df.day_n*daily_interest, 0)

df['balance_w_interest'] = (df.impact+df.interest)

result=df[['customer_id', 'txn_date', 'txn_type', 'txn_amount', 'txn_order', 'impact', 'balance_w_interest']]

result.sort_values(['customer_id', 'txn_date'], ascending=True)
```

First 5 rows.

| customer_id | txn_date   | txn_type | txn_amount | transaction_order | balance | balance_inc_interest |
|-------------|------------|----------|------------|-------------------|------------|---------|
| 1	           | 2020-01-02 | deposit  | 	312        | 1                 |  312     | 312.00  |
| 1	           | 2020-03-05 | purchase | 	612        | 2                 |  -300    | -296.77 |
| 1	           | 2020-03-17 | deposit  | 	324        | 3                 | 24      |  24  |
| 1	           | 2020-03-19 | purchase | 	664        | 4                 |  -640    |  -639.99  |
| 2	           | 2020-01-03 | deposit  | 	549        | 1                 | 549     |  549.00 |
  
