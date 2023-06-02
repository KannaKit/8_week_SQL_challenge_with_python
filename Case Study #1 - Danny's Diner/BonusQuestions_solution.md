# 🍜 Case Study #1 - Danny's Diner
## Bonus Questions
### Join All The Things
The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.

Recreate the following table output using the available data:
| customer_id | order_date | product_name | price | member |
|-------------|------------|--------------|-------|--------|
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |

```TSQL
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
```

| customer_id | order_date | product_name | price | member |
|-------------|------------|--------------|-------|--------|
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |

---
### Rank All The Things
Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

| customer_id | order_date | product_name | price | member | ranking |
|-------|------------|--------------|-------|--------|---------|
| A     | 2021-01-01 | curry        | 15    | N      | null    |
| A     | 2021-01-01 | sushi        | 10    | N      | null    |
| A     | 2021-01-07 | curry        | 15    | Y      | 1       |
| A     | 2021-01-10 | ramen        | 12    | Y      | 2       |
| A     | 2021-01-11 | ramen        | 12    | Y      | 3       |
| A     | 2021-01-11 | ramen        | 12    | Y      | 3       |
| B     | 2021-01-01 | curry        | 15    | N      | null    |
| B     | 2021-01-02 | curry        | 15    | N      | null    |
| B     | 2021-01-04 | sushi        | 10    | N      | null    |
| B     | 2021-01-11 | sushi        | 10    | Y      | 1       |
| B     | 2021-01-16 | ramen        | 12    | Y      | 2       |
| B     | 2021-02-01 | ramen        | 12    | Y      | 3       |
| C     | 2021-01-01 | ramen        | 12    | N      | null    |
| C     | 2021-01-01 | ramen        | 12    | N      | null    |
| C     | 2021-01-07 | ramen        | 12    | N      | null    |

```TSQL
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
```

| er_id | order_date | product_name | price | member | ranking |
|-------|------------|--------------|-------|--------|---------|
| A     | 2021-01-01 | curry        | 15    | N      | null    |
| A     | 2021-01-01 | sushi        | 10    | N      | null    |
| A     | 2021-01-07 | curry        | 15    | Y      | 1       |
| A     | 2021-01-10 | ramen        | 12    | Y      | 2       |
| A     | 2021-01-11 | ramen        | 12    | Y      | 3       |
| A     | 2021-01-11 | ramen        | 12    | Y      | 3       |
| B     | 2021-01-01 | curry        | 15    | N      | null    |
| B     | 2021-01-02 | curry        | 15    | N      | null    |
| B     | 2021-01-04 | sushi        | 10    | N      | null    |
| B     | 2021-01-11 | sushi        | 10    | Y      | 1       |
| B     | 2021-01-16 | ramen        | 12    | Y      | 2       |
| B     | 2021-02-01 | ramen        | 12    | Y      | 3       |
| C     | 2021-01-01 | ramen        | 12    | N      | null    |
| C     | 2021-01-01 | ramen        | 12    | N      | null    |
| C     | 2021-01-07 | ramen        | 12    | N      | null    |

I noticed I had a mistake in my code.
I fixed it on June 2, 2023.
