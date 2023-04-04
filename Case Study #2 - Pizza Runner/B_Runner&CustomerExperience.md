# 🍕 Case Study #2 - Pizza Runner
## 🏃‍♂️ B. Runner and Customer Experience
### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

```TSQL
WITH cte AS (SELECT EXTRACT(WEEK FROM CAST(registration_date AS DATE)) AS registrationWeek, COUNT(runner_id) AS num_runner
FROM pizza_runner.runners
GROUP BY registrationWeek)

SELECT (CASE WHEN registrationweek = 53 THEN 0
        ELSE registrationweek END) AS registrationweek, num_runner
FROM cte;
```

| registrationweek | num_runner |
|------------------|------------|
| 0                | 2          |
| 1                | 1          |
| 2                | 1          |

The CTE part works perfectly except it shows week 0 as week 53 because the week includes last December so it counts as the last week of the last year. 

---

### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pick up the order?

```TSQL
SELECT runner_id, EXTRACT(MINUTE FROM AVG(pickup_time - order_time)) AS Avg_Time_To_HQ
FROM runner_orders1 r
JOIN customer_orders1 c ON r.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY 1;
```

| runner_id | avg_time_to_hq |
|-----------|----------------|
| 1         | 15             |
| 2         | 23             |
| 3         | 10             |

---

### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

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

| num_pizza | avg_prep_time |
|-----------|---------------|
| 1         | 12            |
| 2         | 18            |
| 3         | 29            |

As the number of pizzas increase the average prep time also increases. 

---

### 4. What was the average distance traveled for each customer?

```TSQL
SELECT customer_id, ROUND(AVG(distance)) AS avg_distance
FROM customer_orders1 c
JOIN runner_orders1 r ON r.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY customer_id
ORDER BY customer_id;
```

| customer_id | avg_distance |
|-------------|--------------|
| 101         | 20           |
| 102         | 17           |
| 103         | 23           |
| 104         | 10           |
| 105         | 25           |


---

### 5. What was the difference between the longest and shortest delivery times for all orders?

```TSQL
SELECT MAX(duration)-MIN(duration) difference
FROM runner_orders1
WHERE cancellation IS NULL;
```

| difference | 
|-------------|
| 30         |

---

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

```TSQL
SELECT runner_id, ROUND(AVG(distance::NUMERIC/duration::NUMERIC),2) AS speed_km_per_min
FROM runner_orders1
WHERE cancellation IS NULL
GROUP BY runner_id;
```

| runner_id | speed_km_per_min |
|-----------|------------------|
| 1         | 0.76             |
| 2         | 1.05             |
| 3         | 0.67             |

If we want to know km per hour then,

```TSQL
SELECT runner_id, ROUND(AVG((distance/duration)::NUMERIC)*60.0,2) AS speed_km_per_hour
FROM runner_orders1
WHERE cancellation IS NULL
GROUP BY runner_id;
```

| runner_id | speed_km_per_hour |
|-----------|------------------|
| 1         | 45.54            |
| 2         | 62.90            |
| 3         | 40.00            |

---

### 7. What is the successful delivery percentage for each runner?

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

| runner_id | success_rate |
|-----------|--------------|
| 1         | 100          |
| 2         | 25           |
| 3         | 50           |
