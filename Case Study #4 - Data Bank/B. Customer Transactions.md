# 🏦 Case Study #4 - Data Bank
## 💳 B. Customer Transactions
### 1. What is the unique count and total amount for each transaction type?
###### SQL

```TSQL
SELECT txn_type,
       COUNT(txn_type) n_transaction,
       SUM(txn_amount) total_transaction
FROM customer_transactions
GROUP BY txn_type;
```

###### Python

⚠️`tr` is `transactions` table.

```python
tr.groupby('txn_type').agg({'txn_type':['count'], 'txn_amount':['sum']})
```

| txn_type   | n_transaction | total_transaction |
|------------|---------------|-------------------|
| purchase   | 	1617          | 806537            |
| withdrawal | 	1580          | 793003            |
| deposit    | 	2671          | 1359168           |

---

### 2. What is the average total historical deposit counts and amounts for all customers?
###### SQL

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

###### Python

```python
df = tr[tr['txn_type']=='deposit'].groupby('customer_id').agg({'txn_type':['count'], 'txn_amount':['sum']}) \
.reset_index().rename(columns={'count':'deposit_n', 'sum':'deposit_total'})

df.mean(axis='index')
```

| avg_count_deposit | avg_total_deposit |
|----------------|----------------|
| 5.3              | 2718.3             |

---

### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
###### SQL

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

###### Python

```python
# change data type of txn_date column
tr['txn_date'] = pd.to_datetime(tr.txn_date)

df=tr

# extract month from date
df['month_of_date'] = df['txn_date'].dt.month

# SUM(CASE) statement
result = df.groupby(['customer_id', 'month_of_date']).agg(
    deposit_count=('txn_type', lambda x: np.sum(x == 'deposit')),
    withdrawal_count=('txn_type', lambda x: np.sum(x == 'withdrawal')),
    purchase_count=('txn_type', lambda x: np.sum(x == 'purchase'))
).reset_index()

result = result[(result['deposit_count']>1) & ((result['withdrawal_count']==1) | (result['purchase_count']==1))].groupby('month_of_date')['customer_id'].count().reset_index(name='customer_count')

result
```

| month_n | customer_count |
|----------------|----------------|
| 1              | 115             |
| 2              | 108             |
| 3              | 113             |
| 4              | 50             |

---

### 4. What is the closing balance for each customer at the end of the month?
###### SQL

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

###### Python

For this question, I took a different step to solve compared to the way I did with SQL.

```python
# prepare a dataframe
customer_ids = np.array(tr['customer_id'].unique())
txn_dates = np.array(['2020-01-31', '2020-02-29', '2020-03-31', '2020-04-30'], dtype=np.datetime64)

combinations = []

# create dataframe using for loop
for one in customer_ids:
    for two in txn_dates:
        combinations.append([one, two])
        
df = pd.DataFrame(combinations, columns=['customer_id', 'txn_date'])

df['month_of_date']=df['txn_date'].dt.month

df
```

So far the df looks like this. (First 5 rows)

| customer_id | txn_date   | month_of_date |
|-------------|------------|---------------|
| 1           | 2020-01-31 | 1             |
| 1           | 2020-02-29 | 2             |
| 1           | 2020-03-31 | 3             |
| 1           | 2020-04-30 | 4             |
| 2           | 2020-01-31 | 1             |

```python
txn_df = tr

txn_df = txn_df.sort_values(['customer_id', 'txn_date'], ascending=True)

# determine the order of transactions each month
txn_df['monthly_txn_order'] = txn_df.groupby(['customer_id', 'month_of_date']).cumcount() + 1

# make 'purchase' and 'withdrawal' negative amount
txn_df['txn_amount2'] = np.where(txn_df['txn_type']=='deposit', txn_df.txn_amount, (txn_df.txn_amount*-1))
    
monthly_total = txn_df

# determine culmulative sum of each transaction
monthly_total['cumsum_value'] = monthly_total.sort_values(['customer_id', 'txn_date'], ascending=True).groupby(['customer_id'])['txn_amount2'].cumsum()

# detemine which transaction was made in the end of the month (this doesn't contain the months the customer didn't have any activity)
max_order=monthly_total.groupby(['customer_id', 'month_of_date'])['monthly_txn_order'].max().reset_index(name='max_order_n')

# merge tables to keep only the end of month balance
monthly_total=monthly_total.merge(max_order, how='inner', left_on=['customer_id', 'month_of_date', 'monthly_txn_order'], right_on=['customer_id', 'month_of_date', 'max_order_n'])

# merge with the table we made at first   
merged_df=df.merge(monthly_total, on=['customer_id', 'month_of_date'], how='left').sort_values(['customer_id','month_of_date'], ascending=True)

merged_df
```

Check one thing before moving forward.

```python
merged_df[(merged_df['txn_amount2'].isna()) & (merged_df['month_of_date']==1)]
# there are no customers without transaction history in January, we are good!
```

```python
# if 'cumsum_value' is null that means the customer didn't have any transaction in that month, which indicates the balance hasn't changed since last month, forward fill the value from previous or 2,3 months ago 
merged_df['closing_balance'] = merged_df['cumsum_value'].fillna(method='ffill')

# select relevant columns
result = merged_df[['customer_id', 'txn_date_x', 'closing_balance']].rename(columns={'txn_date_x':'end_date'})

result
```

First 5 rows.

| customer_id | end_date   | closing_balance |
|-------------|------------|-----------------|
| 1	           | 2020-01-31 | 	312             |
| 1	           | 2020-02-29 | 	312             |
| 1	           | 2020-03-31 | 	-640            |
| 1	           | 2020-04-30 | 	-640            |
| 2	           | 2020-01-31 | 	549             |

###### Python Plot

```python
plot=result

plot['month']=np.where(plot['end_date']=='2020-01-31', 'January',
              np.where(plot['end_date']=='2020-02-29', 'February',
              np.where(plot['end_date']=='2020-03-31', 'March', 'April')))

sns.boxplot(x='month', y='closing_balance', data=result).set(title='Boxplot of Closing Balances Across Months')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/307bb2b2-72e0-4273-b93e-135d82f115bd" align="center" width="404" height="278" >

---

### 5. What is the percentage of customers who increase their closing balance by more than 5%?
###### SQL

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

###### Python

```python
df=result

# filter the table so we only have january balance and april balance
df = df[(df['end_date'] == '2020-01-31') | (df['end_date'] == '2020-04-30')]

# create april_balance column
df['april_balance']=df[df['end_date'] == '2020-04-30']['closing_balance']

# back fill na value
df['april_balance']=df['april_balance'].fillna(method='bfill')

# filter again, since we have april balance column next to january balance column we don't need the rows with '2020-04-30'
df = df[df['end_date'] == '2020-01-31']

# create a new column to compare january balance vs. april balance
df['comparison'] = (df.april_balance-df.closing_balance)/df.closing_balance

# count customer with more than 5% increase
more_than_5 = df[df['comparison']>5]['customer_id'].count()

total_customer = tr.customer_id.nunique()

more_than_5/total_customer*100
```

| more_than_five_percent_increase | 
|-------------|
| 12.2      | 	

