# 🍜 Case Study #1 - Danny's Diner
## Case Study Questions
### 1. What is the total amount each customer spent at the restaurant?


```TSQL
SELECT customer_id, sum(price) total_spent
FROM sales
LEFT JOIN menu
  ON sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY 1;
```

customer_id	| total_spent
 --- | --- 
A|	76
B|	74
C|	36

---
### 2. How many days has each customer visited the restaurant?

```TSQL
SELECT customer_id, COUNT(DISTINCT(order_date)) day_count
FROM sales
GROUP BY customer_id;
```

| customer_id | day_count |
|-------------|-----------|
| A           | 4         |
| B           | 6         |
| C           | 2         |

---
### 3. What was the first item from the menu purchased by each customer?

I used DENSE_RANK here because order_date is not time stamped data so we wouldn't know which one is the first order if it's made on the same day.

```TSQL
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
```

| customer_id | order_date | product_name |
|-------------|------------|--------------|
| A           | 2021-01-01 | curry        |
| A           | 2021-01-01 | sushi        |
| B           | 2021-01-01 | curry        |
| C           | 2021-01-01 | ramen        |

> 💡 Difference between `RANK()` and `DENSE_RANK()`
>
>`RANK()` 1,2,3,4,5... number continues even if the values are same.
>
>`DENSE_RANK()` 1,2,2,3,4... asigns same number if the values are same.

---
### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```TSQL
SELECT COUNT(s.product_id) AS most_purchased, product_name
FROM sales s
LEFT JOIN menu m
  ON s.product_id = m.product_id
GROUP BY s.product_id, m.product_name 
ORDER BY most_purchased DESC
LIMIT 1;
```

| most_purchased | product_name |
|-------------|-----------|
| 8          | ramen     |

---
### 5. Which item was the most popular for each customer?

```TSQL
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
```

| customer_id | product_name | ordered_count |
|-------------|--------------|---------------|
| A           | ramen        | 3             |
| B           | sushi        | 2             |
| B           | curry        | 2             |
| B           | ramen        | 2             |
| C           | ramen        | 3             |

---
### 6. Which item was purchased first by the customer after they became a member?

```TSQL
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
```

| customer_id | product_name |
|-------------|-----------|
| A          | curry    |
| B          | sushi     |

---
### 7. Which item was purchased just before the customer became a member?

```TSQL
WITH cte AS (
	SELECT s.customer_id, order_date, product_id, join_date, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date) rank_n 
	FROM sales s
	RIGHT JOIN members m ON s.customer_id = m.customer_id
	WHERE order_date < join_date),
	
cte2 AS(
	SELECT *, MAX(rank_n) OVER(PARTITION BY customer_id) max_row
	FROM cte)

SELECT customer_id, product_name
FROM cte2
LEFT JOIN menu me ON cte2.product_id = me.product_id
WHERE rank_n=max_row
ORDER BY customer_id;
```

| customer_id | product_name |
|-------------|-----------|
| A          | sushi    |
| A          | curry    |
| B          | sushi     |

I accidentaly put the exact same code with question 6, I updated the code on June 1, 2023. 

---
### 8. What is the total items and amount spent for each member before they became a member?

```TSQL
SELECT s.customer_id, COUNT(s.product_id) ordered_count, SUM(price) total_spent
FROM sales s
JOIN menu m
  ON s.product_id = m.product_id
JOIN members AS me
  ON s.customer_id = me.customer_id
WHERE join_date > order_date OR join_date IS NULL
GROUP BY s.customer_id
ORDER BY s.customer_id;
```

| customer_id | ordered_count | total_spent |
|-------------|---------------|-------------|
| A           | 2             | 25          |
| B           | 3             | 40          |

---
### 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

```TSQL
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
```

| customer_id | total_point |
|-------------|-------------|
| A           | 860         |
| B           | 940         |
| C           | 360         |

---
### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

```TSQL
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
GROUP BY d.customer_id;
```

| customer_id | total_point |
|-------------|-------------|
| A           | 1370         |
| B           | 820         |

