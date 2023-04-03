--------------------------------
--CASE STUDY #2: PIZZA RUNNER--
--------------------------------
--Author: Kanna Schellenger
--Date: 04/03/2023
--Tool used: PostgreSQL

--C. Ingredient Optimisation
--Q1. What are the standard ingredients for each pizza?

--Normalize a table
DROP TABLE IF EXISTS pizza_recipes1;
CREATE TABLE pizza_recipes1 AS
(SELECT pizza_id, unnest(string_to_array(toppings, ' ')) topping
FROM   pizza_recipes);

UPDATE pizza_recipes1
SET topping = CASE WHEN topping LIKE '%,' THEN LEFT(topping, LENGTH(topping)-1)
                   ELSE topping
              END;
          
SELECT *
FROM pizza_recipes1;


ALTER TABLE pizza_recipes1
ALTER COLUMN topping TYPE INT
USING (trim(topping)::INT);

-- find out data types
SELECT pg_typeof(topping)
FROM pizza_recipes1;


WITH cte AS (SELECT pizza_name, pr.pizza_id, topping_name
             FROM pizza_runner.pizza_names pn
             INNER JOIN pizza_recipes1 pr ON pn.pizza_id=pr.pizza_id
             INNER JOIN pizza_runner.pizza_toppings pt ON pr.topping=pt.topping_id
             order by pizza_name, pr.pizza_id)

select pizza_name, string_agg(topping_name, ',') as StandardToppings
from cte
group by pizza_name;

--Q2. What was the most commonly added extra?

--(SELECT pizza_id, unnest(string_to_array(toppings, ' ')) topping

DROP TABLE IF EXISTS customer_orders2;
CREATE TABLE customer_orders2 AS (SELECT order_id, customer_id, pizza_id, exclusions, unnest(string_to_array(exclusions, ' ')) exclusions1, extras, unnest(string_to_array(extras, ' ')) extras1, order_time FROM customer_orders1);

SELECT *
FROM customer_orders2;

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

SELECT *
FROM customer_orders2;


SELECT topping_name, COUNT(extras1) topping_count
FROM customer_orders2 co
INNER JOIN pizza_runner.pizza_toppings pt ON co.extras1 = pt.topping_id 
GROUP BY topping_name
ORDER BY topping_count DESC;

--Q3. What was the most common exclusion?

 SELECT topping_name, COUNT(exclusions1) exclusion_count
FROM customer_orders2 co
INNER JOIN pizza_runner.pizza_toppings pt ON co.exclusions1 = pt.topping_id 
GROUP BY topping_name
ORDER BY exclusion_count DESC;

--Q4. Generate an order item for each record in the customers_orders table in the format of one of the following:Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers


DROP TABLE IF EXISTS extras_exclusions;
CREATE TABLE extras_exclusions AS 
  (SELECT order_id, customer_id, pizza_id, 
          split_part(exclusions, ',', 1) AS excl1,
          split_part(exclusions, ',', 2) AS excl2,
          split_part(extras, ',', 1) AS extr1,
          split_part(extras, ',', 2) AS extr2
   FROM customer_orders1
   ORDER BY order_id);
   

ALTER TABLE extras_exclusions
ALTER COLUMN excl1 TYPE INT
USING (TRIM(excl1)::INT),
ALTER COLUMN extr1 TYPE INT
USING (TRIM(extr1)::INT);

UPDATE extras_exclusions
SET excl2 = CASE excl2 WHEN 'null' THEN null
                       WHEN '' THEN null 
            ELSE (TRIM(excl2)::INT) END,
    extr2 = CASE extr2 WHEN 'null' THEN null
                       WHEN '' THEN null 
            ELSE (TRIM(extr2)::INT) END;
            
ALTER TABLE extras_exclusions
ALTER COLUMN excl2 TYPE INT
USING (TRIM(excl2)::INT),
ALTER COLUMN extr2 TYPE INT
USING (TRIM(extr2)::INT);

SELECT *
FROM extras_exclusions;

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


-- Q5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--     For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

-- clean table

DROP TABLE IF EXISTS customer_orders_cleaned;
CREATE TEMP TABLE customer_orders_cleaned AS WITH first_layer AS (
  SELECT
    order_id,
    customer_id,
    pizza_id,
    CASE 
      WHEN exclusions = '' THEN NULL
      WHEN exclusions = 'null' THEN NULL
      ELSE exclusions
    END AS exclusions,
    CASE 
      WHEN extras = '' THEN NULL
      WHEN extras = 'null' THEN NULL
      ELSE extras
    END AS extras,
    order_time
  FROM pizza_runner.customer_orders
 )
 SELECT
   ROW_NUMBER() OVER(
     ORDER BY
       order_id,
       pizza_id
   ) AS row_number_order,
   order_id,
   customer_id,
   pizza_id,
   exclusions,
   extras,
   order_time
 FROM first_layer; 
 
 
 -- Q5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--  For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

-- Step 1: create basic recipe table (recycling question 1)
DROP TABLE IF EXISTS classical_recipe;
CREATE TEMP TABLE classical_recipe AS 
 WITH pizza_recipes_unstacked AS (
   SELECT
     pizza_id,
     CAST(UNNEST(string_to_array(toppings, ', '))AS INT)AS topping_id
   FROM pizza_runner.pizza_recipes)
   SELECT
     t4.row_number_order,
     t4.order_id,
     t4.customer_id,
     t1.pizza_id,
     t1.pizza_name,
     t2.topping_id,
     t3.topping_name
   FROM
     pizza_runner.pizza_names t1
     JOIN pizza_recipes_unstacked t2 ON t1.pizza_id=t2.pizza_id
     JOIN pizza_runner.pizza_toppings t3 ON t2.topping_id=t3.topping_id
     RIGHT JOIN customer_orders_cleaned t4 ON t1.pizza_id=t4.pizza_id;
     
     
 -- Step 2: unpivot extras and exclusions table into 2 separated table:
 
 DROP TABLE IF EXISTS order_exclusions;
 CREATE TEMP TABLE order_exclusions AS 
 SELECT
   row_number_order,
   order_id,
   customer_id,
   t1.pizza_id,
   pizza_name,
   CAST(UNNEST(string_to_array(COALESCE(exclusions, '0'), ','))AS INT) AS exclusions
 FROM
   customer_orders_cleaned t1
 JOIN pizza_runner.pizza_names t2 ON t1.pizza_id=t2.pizza_id
 ORDER BY
   order_id;
   
---

DROP TABLE IF EXISTS order_extras;
 CREATE TEMP TABLE order_extras AS 
 SELECT
   row_number_order,
   order_id,
   customer_id,
   t1.pizza_id,
   pizza_name,
   CAST(UNNEST(string_to_array(COALESCE(extras, '0'), ','))AS INT) AS extras
 FROM
   customer_orders_cleaned t1
 JOIN pizza_runner.pizza_names t2 ON t1.pizza_id=t2.pizza_id
 ORDER BY
   order_id;
   
 --step 3: Join all the tables (Union extras, Except exclusions):

DROP TABLE IF EXISTS pizzas_details;
    CREATE TEMP TABLE pizzas_details AS
    WITH first_layer AS (SELECT
      row_number_order,
      order_id,
      customer_id,
      pizza_id,
      pizza_name,
      topping_id
    FROM
      classical_recipe
    EXCEPT
    SELECT
      *
    FROM
      order_exclusions
    UNION ALL
    SELECT
      *
    FROM
      order_extras
    WHERE
      extras != 0)
    SELECT
      row_number_order,
      order_id,
      customer_id,  
      pizza_id,
      pizza_name,
      first_layer.topping_id,
      topping_name
    FROM
      first_layer
    LEFT JOIN pizza_runner.pizza_toppings ON first_layer.topping_id = pizza_toppings.topping_id
    ORDER BY
      row_number_order,
      order_id,
      pizza_id,
      topping_id;
      
      
 -- Step 4: let's  now reshape the data to answer the question
 WITH counting_table AS(
   SELECT
     row_number_order,
     order_id,
     customer_id,
     pizza_id,
     pizza_name,
     topping_id,
     topping_name,
     COUNT(topping_id) AS count_ingredient
   FROM
     pizzas_details
   GROUP BY
     row_number_order,
     order_id,
     customer_id,
     pizza_id,
     pizza_name,
     topping_id,
     topping_name)
   , text_table AS(
   SELECT
     row_number_order,
     order_id,
     pizza_id,
     pizza_name,
     topping_id,
     CASE WHEN count_ingredient = 1 THEN topping_name
          ELSE CONCAT(count_ingredient, 'x ', topping_name)
     END AS ingredient_count
   FROM counting_table)
   , group_text AS(
   SELECT
     row_number_order,
     order_id,
     pizza_id,
     pizza_name,
     STRING_AGG(ingredient_count, ', ') AS recipe
   FROM
     text_table
   GROUP BY
     row_number_order,
     order_id,
     pizza_id,
     pizza_name)
   SELECT
     row_number_order,
     order_id,
     CONCAT(pizza_name, ': ', recipe)
   FROM
     group_text
   ORDER BY
     row_number_order,
     order_id;

--Q6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

SELECT topping_name, COUNT(topping_id) AS time_used
FROM pizzas_details
GROUP BY topping_id, topping_name
ORDER BY time_used DESC;