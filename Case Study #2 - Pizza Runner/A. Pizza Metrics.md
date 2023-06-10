# 🍕 Case Study #2 - Pizza Runner
### ⚠️ Disclaimer

Some of the queries and Python codes might return different results. I ensured they were at least very similar and answered the question.    
All the tables shown are actually the table markdown I made for my repository [8_Week_SQL_Challenge](https://github.com/KannaKit/8_Week_SQL_Challenge), therefore my Python codes might show slightly different table if you try to run. 

### Import packages

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
```

### Reading in Files

Read files from the [case study](https://8weeksqlchallenge.com/case-study-2/).  
If you need guidance on reading files, I recommend watching this [video](https://www.youtube.com/watch?v=dUpyC40cF6Q&list=PLUaB-1hjhk8FE_XZ87vPPSfHqb6OcM0cF&index=53) I used to learn from. Shout out to [Alex the Analyst](https://www.youtube.com/@AlexTheAnalyst)👏

--- 

## 📏 A. Pizza Metrics
### 1. How many pizzas were ordered?
###### SQL

```TSQL
SELECT COUNT(*)
FROM customer_orders1;
```

###### Python

```python
c_o.order_id.count()
```

count	| 
 --- |
14 |	

---

### 2. How many unique customer orders were made?
###### SQL

```TSQL
SELECT COUNT(DISTINCT order_id)
FROM customer_orders1;
```

###### Python

```python
# count unique order_id
c_o.order_id.nunique()
```

count	| 
 --- |
10 |	

---

### 3. How many successful orders were delivered by each runner?
###### SQL

```TSQL
SELECT runner_id, COUNT(order_id) AS successful_delivery
FROM runner_orders1
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY runner_id;
```

###### Python

```python
success_orders = r_o

# filter out cancelled orders 
success_orders = success_orders[success_orders['cancellation'].isna()]

# count order_id by each runner
success_orders = success_orders.groupby('runner_id')['order_id'].count()

success_orders
```

| runner_id | successful_delivery |
|-----------|---------------------|
| 1         | 4                   |
| 2         | 3                   |
| 3         | 1                   |

###### Python Plot

```python
success_orders.plot(kind = 'bar', title = 'Successful Orders By Each Runner')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/e463e2c8-0290-4902-97a6-d9b91261aa4d" align="center" width="372" height="276" >

---

### 4. How many of each type of pizza was delivered?
###### SQL

```TSQL
SELECT pizza_name, COUNT(pizza_id)
FROM customer_orders1 c
JOIN runner_orders1 r ON c.order_id = r.order_id
JOIN pizza_names pn ON c.pizza_id = pn.pizza_id
WHERE cancellation IS NULL
GROUP BY pizza_id;
```

###### Python

```python
# join r_o, c_o and pizza_names
r_c_n = c_o.merge(r_o, how='left')
r_c_n = r_c_n.merge(pizza_names, how='left')

# count n of pizza which were successfully delivered
type_pizza = r_c_n[r_c_n['cancellation'].isna()].groupby('pizza_name')['order_id'].count()

type_pizza
```

| pizza_name | count |
|-----------|---------------------|
| Meatlovers         | 9                   |
| Vegetarian         | 3                   |

###### Python Plot

```python
type_pizza.plot(kind = 'bar', title = 'A Breakdown of Pizza Types Delivered')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/9587bbb1-48fd-4a50-a0ce-8f9f9bddef47" align="center" width="362" height="324" >

---

### 5. How many Vegetarian and Meatlovers were ordered by each customer?
###### SQL

```TSQL
SELECT customer_id, n.pizza_name, COUNT(c.pizza_id) AS total_count
FROM customer_orders1 c
JOIN pizza_names n ON c.pizza_id = n.pizza_id
GROUP BY customer_id, n.pizza_name
ORDER BY customer_id;
```

###### Python

```python
veg_meat =  r_c_n.groupby(['customer_id', 'pizza_name'])['order_id'].count()

veg_meat
```


| customer_id | pizza_name | total_count |
|-------------|------------|-------------|
| 101         | Meatlovers | 2           |
| 101         | Vegetarian | 1           |
| 102         | Meatlovers | 2           |
| 102         | Vegetarian | 1           |
| 103         | Meatlovers | 3           |
| 103         | Vegetarian | 1           |
| 104         | Meatlovers | 3           |
| 105         | Vegetarian | 1           |

---

### 6. What was the maximum number of pizzas delivered in a single order?
###### SQL

```TSQL
SELECT c.order_id, COUNT(pizza_id) AS total_delivered
FROM customer_orders1 c
JOIN runner_orders1 r ON c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY c.order_id
ORDER BY totalDelivered DESC
LIMIT 1;
```

###### Python

```python
max_pizza = r_c_n[r_c_n['cancellation'].isna()].groupby(['order_id'])['pizza_id'].count()

# creating dataframe using DataFrame constructor
df_max = pd.DataFrame(max_pizza)
 
# max on pizza count
print(df_max.max())
```

| order_id | total_delivered | 
|-------------|------------|
| 4         | 3 | 

---

### 7. For each customer, how many delivered pizzas had at least 1 change, and how many had no changes?
###### SQL

```TSQL
SELECT c.customer_id, 
       SUM(CASE WHEN (exclusions IS NOT NULL) OR (extras IS NOT NULL) THEN 1 ELSE 0 END) AS Atleast1change, 
       SUM(CASE WHEN (exclusions IS NULL) AND (extras IS NULL) THEN 1 ELSE 0 END) AS NoChange
FROM customer_orders1 c
INNER JOIN runner_orders1 r ON c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY c.customer_id
ORDER BY c.customer_id;
```

###### Python

```python
s_orders = r_c_n

s_orders = s_orders[s_orders['cancellation'].isna()]

s_orders['change'] = np.where((s_orders['exclusions'].notnull()) | (s_orders['extras'].notnull()), +1, +0)
s_orders['no_change'] = np.where((s_orders['exclusions'].isna()) & (s_orders['extras'].isna()), +1, +0)

s_orders = s_orders.groupby(['customer_id']).sum()

# reset index
s_orders.reset_index(inplace=True)

# select relevant columns
s_orders[['customer_id', 'change', 'no_change']]
```

| customer_id | Atleast1change | NoChange |
|-------------|------------|-------------|
| 101         | 0 | 2           |
| 102         |0 | 3           |
| 103         | 3 | 0           |
| 104         | 2 | 1           |
| 105         | 1 | 0           |

###### Python Plot

```python
s_orders.plot(kind = 'bar', x='customer_id', y=['change', 'no_change'], stacked = True, title = 'A Breakdown of Pizza Delivered')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/11aea880-cbf0-4860-a106-9263ced93da3" align="center" width="372" height="288" >

---

### 8. How many pizzas were delivered that had both exclusions and extras?
###### SQL

```TSQL
SELECT SUM(CASE WHEN (exclusions IS NOT NULL) AND (extras IS NOT NULL) THEN 1 ELSE 0 END) AS ExclusionsAndExtras
FROM customer_orders1 c
INNER JOIN runner_orders1 r ON c.order_id = r.order_id
WHERE cancellation IS NULL;
```

###### Python

```python
s_orders1 = r_c_n

# filter out cancelled delivery
s_orders1 = s_orders1[s_orders1['cancellation'].isna()]

# count delivered pizza with both exclusions and extras
sum(np.where((s_orders1['exclusions'].notnull()) & (s_orders1['extras'].notnull()), +1, +0))
```

| ExclusionsAndExtras | 
|-------------|
| 1        | 

---

### 9. What was the total volume of pizzas ordered for each hour of the day?
###### SQL

```TSQL
SELECT EXTRACT(hour from order_time) as hourly_data, count(order_id) as total_pizza_ordered
FROM customer_orders1
GROUP BY hourly_data
ORDER BY hourly_data;
```

###### Python

```python
hourly = c_o

# extract hour from order_time
hourly['hour'] = hourly['order_time'].dt.hour

hourly = hourly.groupby('hour')['order_id'].count().reset_index(name='order_count')

hourly
```

| hourly_data | total_pizza_ordered |
|-------------|---------------------|
| 11          | 1                   |
| 13          | 3                   |
| 18          | 3                   |
| 19          | 1                   |
| 21          | 3                   |
| 23          | 3                   |

###### Python Plot

```python
hourly.plot(kind = 'bar', title = 'Order Volume per Hour', x='hour', y='order_count')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/f4e414aa-1ad7-4589-9c96-346126ab7186" align="center" width="372" height="281" >

---

### 10. What was the volume of orders for each day of the week?
###### SQL

```TSQL
SELECT to_char(order_time, 'Day') as daily_data, count(order_id) as total_pizza_ordered
FROM customer_orders1
GROUP BY daily_data
ORDER BY total_pizza_ordered Desc;
```

###### Python

```python
day_n = c_o

# extract day from order_time
day_n['day_name'] = day_n['order_time'].dt.day_name()

day_n = day_n.groupby('day_name')['order_id'].count().sort_values(ascending = False).reset_index(name='order_count')

day_n
```

| daily_data | total_pizza_ordered |
|-------------|---------------------|
| Saturday          | 5                   |
| Wednesday          | 5                   |
| Thursday          | 3                   |
| Friday          | 1                   |

###### Python Plot

```python
day_n.plot(kind = 'bar', title = 'Order Volume per Day of the Week', x='day_name', y='order_count')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/a3bc7167-696a-4c6a-9aa9-fcfebfa3ed2b" align="center" width="362" height="327" >
