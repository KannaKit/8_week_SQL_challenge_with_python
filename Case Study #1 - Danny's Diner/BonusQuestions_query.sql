--------------------------------
--CASE STUDY #1: DANNY'S DINER--
--------------------------------
--Author: Kanna Schellenger
--Date: 03/31/2023
--Tool used: PostgreSQL


/* --------------------
     Bonus Questions
   --------------------*/

-- Join All The Things
-- The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.

SELECT 
  sales.customer_id,
  sales.order_date,
  product_name,
  price,
  (CASE WHEN order_date >= join_date THEN 'Y' ELSE 'N' END) AS member
FROM sales
LEFT JOIN menu ON sales.product_id=menu.product_id
LEFT JOIN members ON sales.customer_id=members.customer_id
ORDER BY sales.customer_id, order_date, product_name;

-- Rank All The Things
-- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

WITH member AS (
SELECT 
  sales.customer_id,
  sales.order_date,
  product_name,
  price,
  (CASE WHEN order_date >= join_date THEN 'Y' ELSE 'N' END) AS member
FROM sales
LEFT JOIN menu ON sales.product_id=menu.product_id
LEFT JOIN members ON sales.customer_id=members.customer_id
ORDER BY sales.customer_id, order_date, product_name)

SELECT 
  *,
  (CASE WHEN member = 'N' THEN NULL
   ELSE DENSE_RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date) END) AS ranking
FROM member;
