# 🍕 Case Study #2 - Pizza Runner
## 🏃‍♂️ B. Runner and Customer Experience
### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
###### SQL

```TSQL
WITH cte AS (SELECT EXTRACT(WEEK FROM CAST(registration_date AS DATE)) AS registrationWeek, COUNT(runner_id) AS num_runner
FROM pizza_runner.runners
GROUP BY registrationWeek)

SELECT (CASE WHEN registrationweek = 53 THEN 0
        ELSE registrationweek END) AS registrationweek, num_runner
FROM cte;
```

###### Python

```python
runners_reg = runners

# extract week number from registration_date column
runners_reg['week_n'] = runners_reg['registration_date'].dt.week

# replace 53rd week to week 0
runners_reg['week_n'] = runners_reg['week_n'].replace(53, 0)

# group by week_n
runners_reg = runners_reg.groupby('week_n')['runner_id'].count()

runners_reg
```

| registrationweek | num_runner |
|------------------|------------|
| 0                | 2          |
| 1                | 1          |
| 2                | 1          |

The CTE part works perfectly except it shows week 0 as week 53 because the week includes last December so it counts as the last week of the last year. 

###### Python Plot

```python
runners_reg.plot(kind = 'bar', title = 'A Breakdown of Runners Signed Up Each Week')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/eb00a2e6-909d-4b0b-95a6-4594e8a9bdad" align="center" width="378" height="276" >

---

### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pick up the order?
###### SQL

```TSQL
SELECT runner_id, EXTRACT(MINUTE FROM AVG(pickup_time - order_time)) AS Avg_Time_To_HQ
FROM runner_orders1 r
JOIN customer_orders1 c ON r.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY 1;
```

###### Python

```python
pickup = r_c_n

# calculate order_time - pickup_time
pickup['toHQ'] = (pickup['pickup_time'] - pickup['order_time'])

# group by runner_id, find average, extract seconds and devide by 60
pickup = pickup.groupby('runner_id')['toHQ'].mean().dt.total_seconds()/60

pickup
```

| runner_id | avg_time_to_hq |
|-----------|----------------|
| 1         | 15             |
| 2         | 23             |
| 3         | 10             |

###### Python Plot

```python
pickup.plot(kind = 'bar', title = 'Average Time to Arrive at HQ for Each Runner (minute)')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/20050da2-d49b-4d57-930d-b2419f95c181" align="center" width="368" height="276" >

---

### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
###### SQL

```TSQL
WITH cte AS (SELECT c.order_id, COUNT(c.order_id) AS Num_pizza, (pickup_time - order_time) AS TimeToPrepare
FROM runner_orders1 r
JOIN customer_orders1 c ON r.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY c.order_id, r.pickup_time, c.order_time         
ORDER BY Num_pizza)

SELECT Num_pizza, EXTRACT(MINUTE FROM AVG(TimeToPrepare)) avg_prep_time
FROM cte
GROUP BY Num_pizza;
```

###### Python

```python
# filter out cancelled orders
r_c_n_s = r_c_n[r_c_n['cancellation'].isna()]

# copy df
time_prepare = r_c_n_s

# calculate order_time - pickup_time
time_prepare['prepare_time'] = (time_prepare['pickup_time'] - time_prepare['order_time'])

# Group the DataFrame by 'order_id', 'pickup_time', and 'order_time', and calculate the count of ordered pizza and time took to prepare pizza(s)
grouped_df = time_prepare.groupby(['order_id', 'pickup_time', 'order_time']).agg(
    n_pizza=('order_id', 'count'), 
    preparation=('prepare_time', 'first')
).reset_index()

result_df = grouped_df.groupby('n_pizza').agg(
    avg_prep_time=('preparation', lambda x: x.dt.total_seconds().mean() / 60)
)

print(result_df)
```

| num_pizza | avg_prep_time |
|-----------|---------------|
| 1         | 12            |
| 2         | 18            |
| 3         | 29            |

As the number of pizzas increase the average prep time also increases. 

###### Python Plot

```python
grouped_df2 = grouped_df

# make prep column show minutes
grouped_df2['prep'] = grouped_df2['preparation'].dt.total_seconds()/60

ax = grouped_df.plot.scatter(x='n_pizza', y='prep', title='Pizza Qantity vs. Preparation Time')
ax.set_xlabel('number of pizza')
ax.set_ylabel('preparation time (min)')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/74fa1408-a3ef-49bb-8905-0d465ba393c0" align="center" width="392" height="278" >

---

### 4. What was the average distance traveled for each customer?
###### SQL

```TSQL
SELECT customer_id, ROUND(AVG(distance)) AS avg_distance
FROM customer_orders1 c
JOIN runner_orders1 r ON r.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY customer_id
ORDER BY customer_id;
```

###### Python

```python
df = r_c_n_s.groupby('customer_id')['distance'].mean()

df
```

| customer_id | avg_distance |
|-------------|--------------|
| 101         | 20           |
| 102         | 17           |
| 103         | 23           |
| 104         | 10           |
| 105         | 25           |

###### Python Plot

```python
df.plot(kind = 'bar', title = 'Average Distance Traveled For Each Customer')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/9c970632-85f0-419f-a831-60ac15d818ae" align="center" width="368" height="288" >

---

### 5. What was the difference between the longest and shortest delivery times for all orders?
###### SQL

```TSQL
SELECT MAX(duration)-MIN(duration) difference
FROM runner_orders1
WHERE cancellation IS NULL;
```

###### Python

```python
max(r_c_n_s.duration)-min(r_c_n_s.duration)
```

| difference | 
|-------------|
| 30         |

---

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
###### SQL

```TSQL
SELECT runner_id, ROUND(AVG((distance/duration)::NUMERIC)*60.0,2) AS speed_km_per_hour
FROM runner_orders1
WHERE cancellation IS NULL
GROUP BY runner_id;
```

###### Python

```python
df = r_o[r_o['cancellation'].isna()]

df['speed'] = (df.distance/df.duration)*60

df = df.groupby('runner_id')['speed'].mean().round(2)

df
```

| runner_id | speed_km_per_hour |
|-----------|------------------|
| 1         | 45.54            |
| 2         | 62.90            |
| 3         | 40.00            |

Runner ID 2 is a lot faster than other 2 runners, however this dataset is too small to really determine that.

###### Python Plot

```python
df.plot(kind='bar', title='Average Speed for Each Runner (mph)')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/b321fed0-65e8-4c0e-b0d0-29cc8a67701f" align="center" width="368" height="276" >

---


### 7. What is the successful delivery percentage for each runner?
###### SQL

```TSQL
WITH cancel AS (SELECT runner_id, 
                      (SUM(CASE WHEN cancellation IS NOT NULL THEN 1
                                WHEN cancellation IS NULL THEN 0
                       ELSE 0 END)) AS canceled_order,
                COUNT(order_id) AS total_order
                FROM runner_orders1
                GROUP BY runner_id)
                
                
SELECT runner_id, 
         (CASE WHEN canceled_order > 0 THEN (canceled_order::float/total_order::float)*100
              WHEN canceled_order = 0 THEN 100
         ELSE 100 END)AS successRate
FROM cancel
ORDER BY 1;
```

###### Python

```python
df = r_o

df['cancelled'] = np.where(df['cancellation'].isna(), +0, +1)
df['successful'] = np.where(df['cancellation'].isna(), +1, +0)


df = df.groupby('runner_id')['cancelled', 'successful'].sum()
df['total'] = df.cancelled + df.successful

df["successful_delivery_rate"] = (df.successful/df.total*100).astype(int)

df = df.reset_index()

df = df[['runner_id', 'successful_delivery_rate']]

df
```

| runner_id | success_rate |
|-----------|--------------|
| 1         | 100          |
| 2         | 25           |
| 3         | 50           |

###### Python Plot

```python
df.plot(kind='bar', x='runner_id', y='successful_delivery_rate', title='Successful Delivery Rate for Each Runner')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/e634e53b-0651-44a1-bb5b-8b8481562151" align="center" width="375" height="276" >


