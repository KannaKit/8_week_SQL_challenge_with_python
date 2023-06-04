# 🍕 Case Study #2 - Pizza Runner
## 📏 A. Pizza Metrics
### 1. How many pizzas were ordered?

```TSQL
SELECT COUNT(*)
FROM customer_orders1;
```

count	| 
 --- |
14 |	

---

### 2. How many unique customer orders were made?

```TSQL
SELECT COUNT(*)
FROM customer_orders1;
```

count	| 
 --- |
10 |	

---

### 3. How many successful orders were delivered by each runner?

```TSQL
SELECT runner_id, COUNT(order_id) AS successful_delivery
FROM runner_orders1
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY runner_id;
```

| runner_id | successful_delivery |
|-----------|---------------------|
| 1         | 4                   |
| 2         | 3                   |
| 3         | 1                   |

---

### 4. How many successful orders were delivered by each runner?

```TSQL
SELECT pizza_id, COUNT(pizza_id)
FROM customer_orders1 c
JOIN runner_orders1 r ON c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY pizza_id;
```

| pizza_id | count |
|-----------|---------------------|
| 1         | 9                   |
| 2         | 3                   |


---

### 5. How many Vegetarian and Meatlovers were ordered by each customer?

```TSQL
SELECT customer_id, n.pizza_name, COUNT(c.pizza_id) AS total_count
FROM customer_orders1 c
JOIN pizza_names n ON c.pizza_id = n.pizza_id
GROUP BY customer_id, n.pizza_name
ORDER BY customer_id;
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

```TSQL
SELECT c.order_id, COUNT(pizza_id) AS total_delivered
FROM customer_orders1 c
JOIN runner_orders1 r ON c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY c.order_id
ORDER BY totalDelivered DESC
LIMIT 1;
```

| order_id | total_delivered | 
|-------------|------------|
| 4         | 3 | 

---

### 7. For each customer, how many delivered pizzas had at least 1 change, and how many had no changes?

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

| customer_id | Atleast1change | NoChange |
|-------------|------------|-------------|
| 101         | 0 | 2           |
| 102         |0 | 3           |
| 103         | 3 | 0           |
| 104         | 2 | 1           |
| 105         | 1 | 0           |

---

### 8. How many pizzas were delivered that had both exclusions and extras?

```TSQL
SELECT SUM(CASE WHEN (exclusions IS NOT NULL) AND (extras IS NOT NULL) THEN 1 ELSE 0 END) AS ExclusionsAndExtras
FROM customer_orders1 c
INNER JOIN runner_orders1 r ON c.order_id = r.order_id
WHERE cancellation IS NULL;
```

| ExclusionsAndExtras | 
|-------------|
| 1        | 

---

### 9. What was the total volume of pizzas ordered for each hour of the day?

```TSQL
SELECT EXTRACT(hour from order_time) as hourly_data, count(order_id) as total_pizza_ordered
FROM customer_orders1
GROUP BY hourly_data
ORDER BY hourly_data;
```

| hourly_data | total_pizza_ordered |
|-------------|---------------------|
| 11          | 1                   |
| 13          | 3                   |
| 18          | 3                   |
| 19          | 1                   |
| 21          | 3                   |
| 23          | 3                   |

---

### 10. What was the volume of orders for each day of the week?

```TSQL
SELECT to_char(order_time, 'Day') as daily_data, count(order_id) as total_pizza_ordered
FROM customer_orders1
GROUP BY daily_data
ORDER BY total_pizza_ordered Desc;
```

| daily_data | total_pizza_ordered |
|-------------|---------------------|
| Saturday          | 5                   |
| Wednesday          | 5                   |
| Thursday          | 3                   |
| Friday          | 1                   |
