--------------------------------
--CASE STUDY #2: PIZZA RUNNER--
--------------------------------
--Author: Kanna Schellenger
--Date: 04/03/2023
--Tool used: PostgreSQL

--B. Runner and Customer Experience
--Q1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
WITH cte AS (SELECT EXTRACT(WEEK FROM CAST(registration_date AS DATE)) AS registrationWeek, COUNT(runner_id) AS num_runner
FROM pizza_runner.runners
GROUP BY registrationWeek)

SELECT (CASE WHEN registrationweek = 53 THEN 0
        ELSE registrationweek END) AS registrationweek, num_runner
FROM cte;

--The CTE part works perfectly except it shows week 0 as week 53 because the week includes last December so it counts as the last week of the last year. 

--Q2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pick up the order?
SELECT runner_id, AVG(pickup_time - order_time) AS AvgTimeToHQ
FROM runner_orders1 r
JOIN customer_orders1 c ON r.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY runner_id;

--Q3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH cte AS (SELECT c.order_id, COUNT(c.order_id) AS Num_pizza, (pickup_time - order_time) AS TimeToPrepare
FROM runner_orders1 r
JOIN customer_orders1 c ON r.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY c.order_id, r.pickup_time, c.order_time         
ORDER BY Num_pizza)

SELECT Num_pizza, AVG(TimeToPrepare)
FROM cte
GROUP BY Num_pizza;

--Q4. What was the average distance traveled for each customer?
SELECT customer_id, ROUND(AVG(distance)) AS AvgDistance
FROM customer_orders1 c
JOIN runner_orders1 r ON r.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY customer_id
ORDER BY customer_id;

--Q5. What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(duration)-MIN(duration)
FROM runner_orders1
WHERE cancellation IS NULL;

--Q6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id, AVG(distance/duration) AS speed_km_per_min
FROM runner_orders1
WHERE cancellation IS NULL
GROUP BY runner_id;

--Q7. What is the successful delivery percentage for each runner?
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
FROM cancel;