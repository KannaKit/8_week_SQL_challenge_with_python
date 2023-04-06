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
    unnest(string_to_array(exclusions, ' ')) exclusions1, 
    unnest(string_to_array(extras, ' ')) extras1, 
    order_time
  FROM customer_orders1);

--TRIM commas, change empty string & 'null' to NULL 
UPDATE customer_orders2
SET extras1 = 
	CASE WHEN extras1 LIKE '%,' THEN TRIM(LEFT(extras1, LENGTH(extras1)-1))
		   WHEN extras1 IS NULL THEN NULL
       WHEN extras1 = '' THEN NULL
		   WHEN extras1 = 'null' THEN NULL
  ELSE extras1 END,
    exclusions1 = 
	CASE WHEN exclusions1 LIKE '%,' THEN TRIM(LEFT(exclusions1, LENGTH(exclusions1)-1))
       WHEN exclusions1 IS NULL THEN NULL
			 WHEN exclusions1 = '' THEN NULL
			 WHEN exclusions1 = 'null' THEN NULL
  ELSE exclusions1 END;
              
--Change data type to integar
ALTER TABLE customer_orders2
ALTER COLUMN extras1 TYPE INT
USING extras1::INT,
ALTER COLUMN exclusions1 TYPE INT
USING exclusions1::INT;
```

It's kind of embarrassing but I had a hard time finding why I can't change the data to INT type, and this helped me to determine what was going on with my table. So I'm gonna share this just in case. 

```TSQL
SELECT 
  extras1,
  CASE WHEN extras1 IS NULL THEN 1 ELSE 0 END AS isnull,
  CASE WHEN extras1 = '' THEN 1 ELSE 0 END AS isempty,
  CASE WHEN extras1 = ' ' THEN 1 ELSE 0 END AS blank,
  CASE WHEN extras1 = 'null' THEN 1 ELSE 0 END AS string_null
FROM customer_orders2;
```

Now, the new table `customer_orders2` looks like this. (First 4 lines)

| order_id | customer_id | pizza_id | exclusions1 | extras1 | order_time          |
|----------|-------------|----------|-------------|---------|---------------------|
| 4        | 103         | 1        | 4           |         | 2020-01-04 13:23:46 |
| 4        | 103         | 1        | 4           |         | 2020-01-04 13:23:46 |
| 4        | 103         | 2        | 4           |         | 2020-01-04 13:23:46 |
| 5        | 104         | 1        | 1           | 1       | 2020-01-08 21:00:29 |

```TSQL
SELECT topping_name, COUNT(extras1) topping_count
FROM customer_orders2 co
INNER JOIN pizza_runner.pizza_toppings pt ON co.extras1::INT = pt.topping_id 
GROUP BY topping_name
ORDER BY topping_count DESC;
```

| topping_name | topping_count |
|-----------|----------------|
| Bacon         | 4             |
| Chicken         | 1             |
| Cheese         | 1             |

---

### 3. What was the most common exclusion?

We can answer to this question easily using the table we made for Q2.

```TSQL
SELECT topping_name, COUNT(exclusions1) exclusion_count
FROM customer_orders2 co
INNER JOIN pizza_runner.pizza_toppings pt ON co.exclusions1 = pt.topping_id 
GROUP BY topping_name
ORDER BY exclusion_count DESC;
```

| topping_name | exclusion_count |
|-----------|----------------|
| Cheese         | 4             |
| Mushrooms         | 1             |
| BBQ Sauce         | 1             |

---

### 4. Generate an order item for each record in the `customers_orders` table in the format of one of the following:
* `Meat Lovers`
* `Meat Lovers - Exclude Beef`
* `Meat Lovers - Extra Bacon`
* `Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers`

First, we are going to make a table to tackle this question. 

```TSQL
DROP TABLE IF EXISTS extras_exclusions;

--there are max 2 different values in the exclusions and extras (ex. '1, 5') we are gonna split into two seperate columns.
CREATE TABLE extras_exclusions AS 
  (SELECT order_id, customer_id, pizza_id, 
          split_part(exclusions, ',', 1) AS excl1,
          split_part(exclusions, ',', 2) AS excl2,
          split_part(extras, ',', 1) AS extr1,
          split_part(extras, ',', 2) AS extr2
   FROM customer_orders1
   ORDER BY order_id);

UPDATE extras_exclusions
SET excl1 = CASE WHEN excl1 IS NULL OR excl1 = '' OR excl1='null' THEN NULL
            ELSE excl1 END,
	excl2 = CASE WHEN excl2 IS NULL OR excl2 = '' OR excl2='null' THEN NULL
            ELSE excl2 END,
    extr1 = CASE WHEN extr1 IS NULL OR extr1 = '' OR extr1='null' THEN NULL
            ELSE extr1 END,
	extr2 = CASE WHEN extr2 IS NULL OR extr2 = '' OR extr2='null' THEN NULL
            ELSE extr2 END;

ALTER TABLE extras_exclusions
ALTER COLUMN excl1 TYPE INT
USING (TRIM(excl1)::INT),
ALTER COLUMN extr1 TYPE INT
USING (TRIM(extr1)::INT),
ALTER COLUMN excl2 TYPE INT
USING (TRIM(excl2)::INT),
ALTER COLUMN extr2 TYPE INT
USING (TRIM(extr2)::INT);
```

Now the table looks like this. (First 5 rows)

| order_id | customer_id | pizza_id | excl1 | excl2 | extr1 | extr2 |
|----------|-------------|----------|-------|-------|-------|-------|
| 1        | 101         | 1        |       |       |       |       |
| 2        | 101         | 1        |       |       |       |       |
| 3        | 102         | 1        |       |       |       |       |
| 3        | 102         | 2        |       |       |       |       |
| 4        | 103         | 1        | 4     |       |       |       |

```TSQL
WITH cte AS (SELECT order_id, ee.pizza_id, pizza_name, pt.topping_name as excl1, pt1.topping_name as excl2, pt2.topping_name as extr1, pt3.topping_name as extr2
             FROM extras_exclusions ee
             LEFT JOIN pizza_runner.pizza_toppings pt ON ee.excl1=pt.topping_id
             LEFT JOIN pizza_runner.pizza_toppings pt1 ON ee.excl2=pt1.topping_id
             LEFT JOIN pizza_runner.pizza_toppings pt2 ON ee.extr1=pt2.topping_id
             LEFT JOIN pizza_runner.pizza_toppings pt3 ON ee.extr2=pt3.topping_id
             LEFT JOIN pizza_runner.pizza_names pn ON ee.pizza_id=pn.pizza_id)
            

SELECT order_id, 
       CASE WHEN pizza_id=1 AND excl1 IS NULL AND extr1 IS NULL THEN concat(pizza_name, excl1, ' ', extr1)
            WHEN pizza_id=1 AND excl1 IS NOT NULL AND excl2 IS NULL AND extr1 IS NULL AND extr2 IS NULL THEN concat(pizza_name,' - Exclude', ' ', excl1)
            WHEN pizza_id=1 AND excl1 IS NOT NULL AND excl2 IS NOT NULL AND extr1 IS NOT NULL AND extr2 IS NULL THEN concat(pizza_name,' - Exclude', ' ', excl1, ', ', excl2, ' - Extra', ' ', extr1)
            WHEN pizza_id=1 AND excl1 IS NOT NULL AND excl2 IS NOT NULL AND extr1 IS NOT NULL AND extr2 IS NOT NULL THEN concat(pizza_name,' - Exclude', ' ', excl1, ', ', excl2, ' - Extra', ' ', extr1, ', ', extr2)
            WHEN pizza_id=1 AND excl1 IS NULL AND extr1 IS NOT NULL AND extr2 IS NULL THEN concat(pizza_name,' - Extra', ' ', extr1)
            WHEN pizza_id=1 AND excl1 IS NULL AND extr1 IS NOT NULL AND extr2 IS NOT NULL THEN concat(pizza_name,' - Extra', ' ', extr1)
            WHEN pizza_id=2 AND excl1 IS NULL AND extr1 IS NULL THEN concat(pizza_name, excl1, ' ', extr1)
            WHEN pizza_id=2 AND excl1 IS NOT NULL AND excl2 IS NULL AND extr1 IS NULL AND extr2 IS NULL THEN concat(pizza_name,' - Exclude', ' ', excl1)
            WHEN pizza_id=2 AND excl1 IS NOT NULL AND excl2 IS NOT NULL AND extr1 IS NOT NULL AND extr2 IS NULL THEN concat(pizza_name,' - Exclude', ' ', excl1, ', ', excl2, ' - Extra', ' ', extr1)
            WHEN pizza_id=2 AND excl1 IS NOT NULL AND excl2 IS NOT NULL AND extr1 IS NOT NULL AND extr2 IS NOT NULL THEN concat(pizza_name,' - Exclude', ' ', excl1, ', ', excl2, ' - Extra', ' ', extr1, ', ', extr2)    
            WHEN pizza_id=2 AND excl1 IS NULL AND extr1 IS NOT NULL AND extr2 IS NULL THEN concat(pizza_name,' - Extra', ' ', extr1)
            WHEN pizza_id=2 AND excl1 IS NULL AND extr1 IS NOT NULL AND extr2 IS NOT NULL THEN concat(pizza_name,' - Extra', ' ', extr1, ', ', extr2)
       ELSE pizza_name END AS pizza_details
FROM cte
ORDER BY order_id;
```

First 5 rows will look like this.

| order_id | pizza_details               |
|----------|-----------------------------|
| 1        | Meatlovers                  |
| 2        | Meatlovers                  |
| 3        | Vegetarian                  |
| 3        | Meatlovers                  |
| 4        | Vegetarian - Exclude Cheese |

It works but I'm sure there are probably milion better and simpler ways to do it, and I'd love to know if anyone knows 😹

---

### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the `customer_orders` table and add a 2x in front of any relevant ingredients

For example: `"Meat Lovers: 2xBacon, Beef, ... , Salami"`

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
