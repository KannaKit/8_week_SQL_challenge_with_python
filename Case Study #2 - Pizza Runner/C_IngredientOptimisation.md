# 🍕 Case Study #2 - Pizza Runner
## 🏃‍♂️ C. Ingredient Optimisation
### 1. What are the standard ingredients for each pizza?

I had to do extra data cleaning in order to answer this question.

```TSQL
--Normalize a table
DROP TABLE IF EXISTS pizza_recipes1;
CREATE TABLE pizza_recipes1 AS
(SELECT pizza_id, unnest(string_to_array(toppings, ' ')) topping
FROM   pizza_recipes);

UPDATE pizza_recipes1
SET topping = CASE WHEN topping LIKE '%,' THEN LEFT(topping, LENGTH(topping)-1)
                   ELSE topping
              END;

ALTER TABLE pizza_recipes1
ALTER COLUMN topping TYPE INT
USING (trim(topping)::INT);
```
Now, the new table `pizza_recipes1` looks like this. (First 10 lines)

| pizza_id | topping |
|----------|---------|
| 1        | 2       |
| 1        | 3       |
| 1        | 4       |
| 1        | 5       |
| 1        | 6       |
| 1        | 8       |
| 1        | 10      |
| 2        | 4       |
| 2        | 6       |

```TSQL
WITH cte AS (SELECT pizza_name, pr.pizza_id, topping_name
             FROM pizza_names pn
             INNER JOIN pizza_recipes1 pr ON pn.pizza_id=pr.pizza_id
             INNER JOIN pizza_toppings pt ON pr.topping=pt.topping_id
             order by pizza_name, pr.pizza_id)

select pizza_name, string_agg(topping_name, ', ') as standard_toppings
from cte
group by pizza_name;
FROM cte;
```

| pizza_name | standard_toppings                                              |
|------------|----------------------------------------------------------------|
| Meatlovers | BBQ Sauce, Pepperoni, Cheese, Salami, Chicken, Bacon, Mushrooms, Beef |
| Vegetarian | Tomato Sauce, Cheese, Mushrooms, Onions, Peppers, Tomatoes          |

---

### 2. What was the most commonly added extra?

And, more unnesting columns...

```TSQL
DROP TABLE IF EXISTS customer_orders2;
CREATE TABLE customer_orders2 AS (
  SELECT 
    order_id, 
    customer_id, 
    pizza_id, 
    exclusions, 
    unnest(string_to_array(exclusions, ' ')) exclusions1, 
    extras, 
    unnest(string_to_array(extras, ' ')) extras1, 
    order_time 
  FROM customer_orders1);

UPDATE customer_orders2
SET extras1 = CASE WHEN extras1 LIKE '%,' THEN LEFT(extras1, LENGTH(extras1)-1)
                   WHEN extras1 IS NULL THEN NULL
              ELSE extras1 END,
    exclusions1 = CASE WHEN exclusions1 LIKE '%,' THEN LEFT(exclusions1, LENGTH(extras1)-1)
                   WHEN exclusions1 IS NULL THEN NULL
              ELSE exclusions1 END;
              
ALTER TABLE customer_orders2
ALTER COLUMN extras1 TYPE INT
USING (trim(extras1)::INT),
ALTER COLUMN exclusions1 TYPE INT
USING (trim(exclusions1)::INT);
```

Now, the new table `customer_orders2` looks like this. 



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

Runner ID 2 is a lot faster than other 2 runners, however this dataset is too small to really determine that.

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
