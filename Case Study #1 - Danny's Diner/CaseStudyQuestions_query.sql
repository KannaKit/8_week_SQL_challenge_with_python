--------------------------------
--CASE STUDY #1: DANNY'S DINER--
--------------------------------
--Author: Kanna Schellenger
--Date: 03/31/2023
--Tool used: PostgreSQL


/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, sum(price) total_spent
FROM sales
LEFT JOIN menu
  ON sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY 1;

-- 2. How many days has each customer visited the restaurant
SELECT customer_id, COUNT(DISTINCT(order_date)) day_count
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH first AS 
  (SELECT 
     product_id, 
     customer_id, 
     order_date, 
     DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date)AS ranking
    FROM sales)
             
SELECT customer_id, order_date, product_name
FROM first
LEFT JOIN menu
  ON first.product_id = menu.product_id
WHERE ranking = 1
GROUP BY first.customer_id, product_name, order_date
ORDER BY customer_id;
-- DENSE_RANK is used because the order_date is not time stamped hence, we don't know which item is ordered first ifmltiple items are ordered on the same day. 
--（DENSE RANK例：1位 5pt　2位 4pt　2位 4pt　3位 3pt）/（RANKの例：1位 5pt　2位 4pt　2位 4pt　4位 3pt）/（ROW_NUMBERの例：1位 5pt　2位 4pt　3位 4pt　4位 3pt）

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT COUNT(s.product_id) AS most_purchased, product_name
FROM sales s
LEFT JOIN menu m
  ON s.product_id = m.product_id
GROUP BY s.product_id, m.product_name 
ORDER BY most_purchased DESC
LIMIT 1;


-- 5. Which item was the most popular for each customer?
WITH pop AS (
	SELECT 
	  product_id, 
	  customer_id, 
	  COUNT(product_id) ordered_count, 
	  DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(product_id) DESC)AS ranking
    FROM sales
    GROUP BY customer_id, product_id)
            
SELECT customer_id, product_name, ordered_count
FROM pop
LEFT JOIN menu m
  ON pop.product_id = m.product_id
WHERE ranking = 1
ORDER BY customer_id;

-- 6. Which item was purchased first by the customer after they became a member?
WITH first_purchase_asMenmber AS (
	SELECT 
	  me.customer_id, 
	  m.product_name, 
	  order_date, 
	  join_date, 
	  DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date) AS ranking
    FROM sales s
    INNER JOIN members me ON me.customer_id = s.customer_id
    LEFT JOIN menu m ON s.product_id = m.product_id
    WHERE order_date >= join_date)
 
SELECT customer_id, product_name
FROM first_purchase_asMenmber
WHERE ranking = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH first_purchase_asMenmber AS (
	SELECT 
	  me.customer_id, 
      m.product_name, 
	  order_date, join_date, 
	  DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date DESC) AS ranking
    FROM sales s
    INNER JOIN members me ON me.customer_id = s.customer_id
    LEFT JOIN menu m ON s.product_id = m.product_id
    WHERE order_date < join_date)

SELECT customer_id, product_name
FROM first_purchase_asMenmber
WHERE ranking = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(s.product_id) ordered_count, SUM(price) total_spent
FROM sales s
JOIN menu m
  ON s.product_id = m.product_id
JOIN members AS me
  ON s.customer_id = me.customer_id
WHERE join_date > order_date OR join_date IS NULL
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH point AS (SELECT *,
                CASE WHEN product_id = 1 THEN price * 20
                ELSE price * 10
                END AS pt
               FROM menu)

SELECT customer_id, sum(pt) total_point
FROM point p
LEFT JOIN sales s
  ON p.product_id = s.product_id
GROUP BY customer_id
ORDER BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH dates_cte AS 
(
 SELECT *, 
  join_date + INTERVAL '6 day' AS valid_date,
  date_trunc('month', join_date) + interval '1 month' - interval '1 day' AS last_date
 FROM members
)

SELECT d.customer_id, SUM(CASE WHEN s.product_id = 1 THEN price * 20
                            WHEN order_date BETWEEN join_date AND valid_date THEN price * 20
                       ELSE price * 10
                       END) AS total_point
FROM dates_cte d
JOIN sales s
ON d.customer_id = s.customer_id
JOIN menu m
ON s.product_id = m.product_id
WHERE order_date < d.last_date
GROUP BY d.customer_id
ORDER BY 1;
  

  
  
