--------------------------------
--CASE STUDY #2: PIZZA RUNNER--
--------------------------------
--Author: Kanna Schellenger
--Date: 04/03/2023
--Tool used: PostgreSQL

-- D. Pricing and Ratings
-- Q1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

SELECT SUM(CASE WHEN pizza_id = 1 THEN 12
                WHEN pizza_id = 2 THEN 10
           ELSE pizza_id END) AS total_sales
FROM customer_orders_cleaned t1
JOIN runner_orders1 t2 ON t1.order_id=t2.order_id
WHERE cancellation IS NULL;

-- Q2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra


SELECT SUM(CASE WHEN pizza_id = 1 THEN 12
                WHEN pizza_id = 2 THEN 10
           ELSE 0 END) +
       SUM(CASE WHEN extr1 IS NOT NULL AND extr2 IS NULL THEN 1
                WHEN extr2 IS NOT NULL AND extr2 IS NOT NULL THEN 2
           ELSE 0 END)AS total_sales
FROM extras_exclusions t1
JOIN runner_orders1 t2 ON t1.order_id=t2.order_id
WHERE cancellation IS NULL;

-- Q3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

DROP TABLE IF EXISTS ratings;
CREATE TABLE ratings  (
  "order_id" INTEGER,
  "rating" INTEGER CONSTRAINT check1to5_raating CHECK (
     "rating" between 1 and 5),
  "comment" VARCHAR(150)
);

INSERT INTO ratings 
  ("order_id", "rating", "comment")
VALUES
  (1, 5, 'Good service'),
  (2, 4, 'Good'),
  (3, 5, ''),
  (4, 3, 'Pizza arrived cold'),
  (5, 2, 'Rude delivery person'),
  (6, 5, ''),
  (7, NULL, ''),
  (8, NULL, ''),
  (9, 5, ''),
  (10, 5, 'Delicious pizza');
  
SELECT *
FROM ratings;


--Q4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
--customer_id
--order_id
--runner_id
--rating
--order_time
--pickup_time
--Time between order and pickup
--Delivery duration
--Average speed
--Total number of pizzas

DROP TABLE IF EXISTS new_tb;
CREATE TABLE new_tb AS

(SELECT 
  t1.customer_id,
  t1.order_id,
  t2.runner_id,
  t3.rating,
  order_time,
  pickup_time,
  (pickup_time-order_time) as time_between_order_and_pickup,
  duration,
  ROUND(CAST(AVG(distance/duration*60)as numeric),1) as avg_speed,
  COUNT(t1.pizza_id) as total_n_of_pizzas
FROM customer_orders1 t1
JOIN runner_orders1 t2 ON t1.order_id=t2.order_id
JOIN ratings t3 ON t1.order_id=t3.order_id
WHERE cancellation IS NULL
GROUP BY t1.order_id, t1.customer_id, t2.runner_id, t3.rating, t1.order_time, t2.pickup_time, t2.duration
ORDER BY order_id);

SELECT *
FROM new_tb;


-- Q5.If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

WITH cte AS 
 (SELECT SUM(CASE WHEN pizza_id = 1 THEN 12
                  WHEN pizza_id = 2 THEN 10
             ELSE 0 END) as pizza_price
         --distance,
         --ROUND(CAST((distance*0.3) AS NUMERIC),2) as runner_pay
  FROM customer_orders1 t1 
  LEFT JOIN runner_orders1 t2 ON t1.order_id=t2.order_id
  WHERE cancellation IS NULL)
     ,runner_p AS
 (SELECT SUM(ROUND(CAST((distance*0.3) AS NUMERIC),2)) as runner_pay
  FROM runner_orders1
  WHERE cancellation IS NULL)

SELECT t1.pizza_price-t2.runner_pay as revenues_after_delivery
FROM cte t1, runner_p t2;