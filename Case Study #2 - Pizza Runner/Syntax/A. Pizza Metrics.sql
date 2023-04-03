--------------------------------
--CASE STUDY #2: PIZZA RUNNER--
--------------------------------
--Author: Kanna Schellenger
--Date: 04/03/2023
--Tool used: PostgreSQL

--A. Pizza Metrics
--Q1. How many pizzas were ordered?
SELECT COUNT(*)
FROM customer_orders1;

--Q2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id)
FROM customer_orders1;

--Q3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id) AS successful_delivery
FROM runner_orders1
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY runner_id;

--Q4. How many of each type of pizza was delivered?
SELECT pizza_id, COUNT(pizza_id)
FROM customer_orders1 c
JOIN runner_orders1 r ON c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY pizza_id;

--Q5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id, n.pizza_name, COUNT(c.pizza_id) AS TotalPizzaOrdered
FROM customer_orders1 c
JOIN pizza_runner.pizza_names n ON c.pizza_id = n.pizza_id
GROUP BY customer_id, n.pizza_name
ORDER BY customer_id;

--Q6. What was the maximum number of pizzas delivered in a single order?
SELECT c.order_id, COUNT(pizza_id) AS totalDelivered
FROM customer_orders1 c
JOIN runner_orders1 r ON c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY c.order_id
ORDER BY totalDelivered DESC
LIMIT 1;

--Q7. For each customer, how many delivered pizzas had at least 1 change, and how many had no changes?
SELECT c.customer_id, 
       SUM(CASE WHEN (exclusions IS NOT NULL) OR (extras IS NOT NULL) THEN 1 ELSE 0 END) AS Atleast1change, 
       SUM(CASE WHEN (exclusions IS NULL) AND (extras IS NULL) THEN 1 ELSE 0 END) AS NoChange
FROM customer_orders1 c
INNER JOIN runner_orders1 r ON c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY c.customer_id
ORDER BY c.customer_id;

--Q8. How many pizzas were delivered that had both exclusions and extras?
SELECT SUM(CASE WHEN (exclusions IS NOT NULL) AND (extras IS NOT NULL) THEN 1 ELSE 0 END) AS ExclusionsAndExtras
FROM customer_orders1 c
INNER JOIN runner_orders1 r ON c.order_id = r.order_id
WHERE cancellation IS NULL;

--Q9. What was the total volume of pizzas ordered for each hour of the day?
SELECT EXTRACT(hour from order_time) as hourlydata, count(order_id) as totalPizzaOrdered
FROM customer_orders1
GROUP BY hourlydata
ORDER BY hourlydata;

--Q10. What was the volume of orders for each day of the week?
SELECT to_char(order_time, 'Day') as DailyData, count(order_id) as totalPizzaOrdered
FROM customer_orders1
GROUP BY DailyData
ORDER BY totalPizzaOrdered Desc;

