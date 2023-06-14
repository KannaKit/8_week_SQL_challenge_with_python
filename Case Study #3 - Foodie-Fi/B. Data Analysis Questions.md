# 🥑 Case Study #3 - Foodie-Fi
## ❓ B. Data Analysis Questions
### 1. How many customers has Foodie-Fi ever had?
###### SQL

```TSQL
SELECT COUNT(DISTINCT customer_id)
FROM subscriptions;
```

###### Python

```python
subscriptions.customer_id.nunique()
```

| count | 
|-------------|
| 1000	           | 

---

### 2. What is the monthly distribution of `trial` plan `start_date` values for our dataset - use the start of the month as the group by value
###### SQL

```TSQL
SELECT EXTRACT(MONTH FROM start_date) month_by_month, COUNT(customer_id) n_of_customers
FROM subscriptions
WHERE plan_id=0
GROUP BY month_by_month
ORDER BY n_of_customers DESC;
```

###### Python

```python
# change data type for order_time to datetime
subscriptions['start_date'] = pd.to_datetime(subscriptions.start_date)

df=subscriptions[subscriptions['plan_id']==0]

# extract month from date
df['month_of_date'] = df['start_date'].dt.month

monthly = df.groupby('month_of_date')['customer_id'].count().sort_values(ascending=False).reset_index(name='customer_count')

monthly
```

First 5 rows.

| month_by_month | n_of_customers |
|----------------|----------------|
| 3              | 94             |
| 7              | 89             |
| 5              | 88             |
| 1              | 88             |
| 8              | 88             |

###### Python Plot

```python
monthly_plot = monthly.sort_values('month_of_date', ascending=True)

monthly_plot.plot(kind='bar', x='month_of_date', y='customer_count')

# add an average line
plt.axhline(y=np.nanmean(monthly_plot.customer_count))
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/87767c7c-9547-4b5e-a1cb-d7baa6b14f1d" align="center" width="375" height="266" >

---

### 3. What plan `start_date` values occur after the year 2020 for our dataset? Show the breakdown by count of events for each `plan_name`
###### SQL

```TSQL
SELECT plan_name, COUNT(t1.plan_id) count_event
FROM subscriptions t1
JOIN plans t2 ON t1.plan_id = t2.plan_id
WHERE EXTRACT(YEAR FROM start_date) > 2020
GROUP BY plan_name
ORDER BY count_event DESC;
```

###### Python

```python
theDate = '2021-01-01 00:00:00'

# create a dataframe contains only data after year 2020
year21 = subscriptions[subscriptions['start_date']>=theDate] 

# merge with plans table
year21 = year21.merge(plans, how='inner')

year21 = year21.groupby('plan_name')['plan_name'].count().sort_values(ascending=False).reset_index(name='customer_count')

year21
```

| plan_name     | count_event |
|---------------|-------------|
| churn         | 	71          |
| pro annual    | 	63          |
| pro monthly   | 	60          |
| basic monthly | 	8           |

###### Python Plot

```python
year21.plot(kind='bar', x='plan_name', y='customer_count', title='The Breakdown of Plans in 2021')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/53679811-4953-4c6e-9910-c6a35332562a" align="center" width="368" height="339" >

---

### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
###### SQL

```TSQL
WITH cte AS (
   SELECT COUNT(DISTINCT customer_id) customer_count, CAST(COUNT(customer_id)AS NUMERIC) n_churn 
   FROM subscriptions
   WHERE plan_id=4 )

SELECT customer_count, ROUND((n_churn/1000)*100,1) perc_churned
FROM cte;
```

###### Python

```python
churn = subscriptions[subscriptions['plan_id']==4]

churn_n = churn['customer_id'].nunique()

total_customer_n = subscriptions['customer_id'].nunique()

churn_perc = (churn_n/total_customer_n*100.0)

data = {
    'churn_n': [churn_n],
    'churn_perc': [churn_perc]
}

df = pd.DataFrame.from_dict(data)

df
```

| customer_count     | perc_churned |
|---------------|-------------|
| 307         | 	30.7       |

---

### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
###### SQL

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

###### Python

```python
trial_to_churn = subscriptions

trial_to_churn['plan_rank']=trial_to_churn.groupby('customer_id')['start_date'].rank(method='first').astype(int)

# make sure all the trial is plan_rank==1
len(trial_to_churn[(trial_to_churn['plan_id']==0) &
                   (~trial_to_churn['plan_rank']==1)])
```

```python
trial_to_churn = len(trial_to_churn[(trial_to_churn['plan_id']==4) & (trial_to_churn['plan_rank']==2)])

trial_to_churn_perc = ((trial_to_churn/total_customer_n)*100.0)

data = {
    'trial_to_churn': [trial_to_churn],
    'trial_to_churn_perc': [trial_to_churn_perc]
}

df = pd.DataFrame.from_dict(data)

df['trial_to_churn_perc'] = df['trial_to_churn_perc'].round(0).astype(int)

df
```

| churn_count     | churn_percentage |
|---------------|-------------|
| 92         | 	9       |

---

### 6. What is the number and percentage of customer plans after their initial free trial?
###### SQL

```TSQL
WITH ranking AS (
 SELECT s.customer_id, 
        s.plan_id, 
        p.plan_name, 
        ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.plan_id) AS plan_rank
 FROM subscriptions s
 JOIN plans p ON s.plan_id=p.plan_id
 )
 
 SELECT plan_name, COUNT(DISTINCT customer_id) n_customer, ROUND((CAST(COUNT(DISTINCT customer_id) AS NUMERIC)/(SELECT CAST(COUNT(DISTINCT customer_id)AS NUMERIC) FROM subscriptions))*100,1) percentage
 FROM ranking
 WHERE plan_rank=2
 GROUP BY plan_name
 ORDER BY n_customer DESC;
```

###### Python

```python
after_trial = subscriptions

after_trial['plan_order']=after_trial.groupby('customer_id')['start_date'].rank(method='first').astype(int)

after_trial = after_trial[after_trial['plan_order']==2].merge(plans, how='inner')

after_trial = after_trial.groupby('plan_name')['customer_id'].nunique().sort_values(ascending=False).reset_index(name='customer_count')

after_trial['percentage'] = after_trial['customer_count']/total_customer_n*100.0

after_trial
```

| plan_name     | n_customer | percentage |
|---------------|------------|------------|
| basic monthly | 546        | 54.6       |
| pro monthly   | 325        | 32.5       |
| churn         | 	92         | 9.2        |
| pro annual    | 	37         | 3.7        |

###### Python Plot

```python
plt.pie(after_trial.percentage, labels = after_trial.plan_name)
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/9a0143ed-bcda-489d-aeeb-e7d874c62821" align="center" width="271" height="231" >

---

### 7. What is the customer count and percentage breakdown of all 5 `plan_name` values at `2020–12–31`?
###### SQL

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

###### Python

```python
df = subscriptions

df['next_date'] = df.sort_values('start_date', ascending=True).groupby('customer_id')['start_date'].shift(-1)

filtered_df = df[((~df['next_date'].isna()) & (df['start_date'] < '2020-12-31') & (df['next_date'] > '2020-12-31')) | (df['next_date'].isna()) & (df['start_date'] < '2020-12-31')]

grouped_df = filtered_df.groupby('plan_id')['customer_id'].count().reset_index(name='customer_n')

grouped_df['percentage'] = grouped_df.customer_n*100/total_customer_n

result_df = grouped_df.merge(plans, how='inner')

result_df = result_df[['plan_name', 'customer_n', 'percentage']]
```


| plan_id | number_customer | pct_each_plan |
|---------|-----------------|---------------|
| 0       | 19              | 1.00          |
| 1       | 224             | 22.00         |
| 2       | 326             | 32.00         |
| 3       | 195             | 19.00         |
| 4       | 235             | 23.00         |

###### Python Plot

```python
plt.pie(result_df.percentage, labels = result_df.plan_name)
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/29f1f6d9-6bf7-4f48-b1d4-61ce8038bf59" align="center" width="289" height="231" >

---

### 8. How many customers have upgraded to an annual plan in 2020?
###### SQL

```TSQL
WITH cte AS(
   SELECT customer_id, plan_id, EXTRACT(YEAR FROM start_date::timestamp) yr
   FROM subscriptions
)
 
 SELECT COUNT(customer_id) n_customer
 FROM cte
 WHERE plan_id=3 AND yr='2020';
```

###### Python

```python
df20 = subscriptions[subscriptions['start_date']<='2020-12-31']

df20_annual = df20[df20['plan_id']==3]

df20_annual['customer_id'].count()
```

| n_customer | 
|---------|
| 195      | 

---

### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
###### SQL

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

###### Python

```python
# determine which customer joined annual plan
annual_id = subscriptions[subscriptions['plan_id']==3]

# make it to list
annual_id = annual_id.customer_id.to_list()

# filter subscriptions table using the list 
df = subscriptions[subscriptions['customer_id'].isin(annual_id)]

# create a column to store the day the customer started the annual plan
df['day_annual']=df[df['plan_id']==3]['start_date']

# copy a table
df_day1 = df

# store customer_id and start_date of their first plan
df_day1=df_day1[df_day1['plan_order']==1][['customer_id', 'start_date']]

# change a column name to 'day1'
df_day1=df_day1.rename(columns={'start_date':'day1'})

# merge two tables
df = df.merge(df_day1, how='left', on='customer_id')

# keep rows only with annual plan rows
df = df[df['plan_id']==3]

# create a new column to day_annual subtract by day_1 to determine how many days it took for customers to change to the annual plan
df['days_to_annual']=df.day_annual-df.day1

# calculate the average
df.days_to_annual.mean()
```

| avg_days_to_upgrade | 
|---------|
| 105      | 

###### Python Plot

```python
plot_df = df

# create a new column to get rid of 'days' from 'days_to_annual' column
plot_df['days_to_annual2'] = pd.to_timedelta(plot_df.days_to_annual, errors='coerce').dt.days

# create a distribution plot using seaborn
sns.displot(df, x="days_to_annual2").set(title='Days to Switch to Annual Plan from Joining Day', xlabel='days')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/ce12c60f-069d-4ea4-9e84-4029d6f6c93e" align="center" width="352" height="367" >

---

### 10. Can you further breakdown this average value into 30 day periods (i.e. 0–30 days, 31–60 days etc)
###### SQL

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

###### Python

```python
day_bin = np.floor_divide(df.days_to_annual2, 30)
day_bin = np.clip(day_bin,0,12)

day_bin = day_bin.reset_index()

day_bin = day_bin.groupby('days_to_annual2')['days_to_annual2'].count().reset_index(name='customer_n')

day_bin=day_bin.rename(columns={'days_to_annual2':'breakdown'})

# Convert day_bin to a numpy array
day_bin_array = day_bin.values.flatten()

# Define the bin edges and labels
bin_edges = np.arange(0, 361, 30)
bin_labels = [(bin_edges[i], bin_edges[i+1]) for i in range(len(bin_edges)-1)]
bin_labels = [f"{start} - {end} days" for start, end in bin_labels]

day_bin['breakdown'] = bin_labels

day_bin
```

First 5 rows.

| breakdown      | customers |
|----------------|-----------|
| 0 - 30 days    | 48        |
| 30 - 60 days   | 25        |
| 60 - 90 days   | 33        |
| 90 - 120 days  | 35        |
| 120 - 150 days | 43        |

> `WIDTH_BUCKET` is a function that assigns values to buckets.
>
> I added `customer_id` and `n_days_till_upgrade` (day_upgrade-day1) columns to CTE 'bins' to make it easier to understand, and the table looks like this. (First 5 rows)
>
> | customer_id | n_days_till_upgrade | day_bin |
> |-------------|---------------------|---------------------|
> | 2           | 7                   | 1                   |
> | 9           | 7                   | 1                   |
> | 16          | 143                 | 5                   |
> | 17          | 137                 | 5                   |
> | 19          | 68                  | 3                   |
>
> The first row means customer 2 took 7 days to upgrade to the `pro monthly` plan, and "7 days" fall in the #1 bin. 

---

### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
###### SQL

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

###### Python

```python
# create a 'next_plan' column
df['next_plan'] = subscriptions.sort_values(['customer_id', 'start_date'], ascending=True).groupby('customer_id')['plan_id'].shift(-1)

# count with conditions
df[(df['plan_id']==2) & (df['next_plan']==1) & (df['start_date']<='2020-12-31')]['customer_id'].count()
```

| n_customer      | 
|----------------|
|0    | 
