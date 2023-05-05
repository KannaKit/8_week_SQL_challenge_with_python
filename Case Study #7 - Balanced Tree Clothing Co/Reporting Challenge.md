# 🌄 Case Study #7 - Balanced Tree Clothing Co.
## 🗒️ Reporting Challenge

Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.

Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.

He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the same analysis for February without many changes (if at all).

Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks :)

First, I made a section to put year and month.
 
```TSQL
--create a table with one month data
DROP TABLE IF EXISTS one_month_tbl;
CREATE TABLE one_month_tbl AS (
 SELECT *
 FROM sales
 --insert year and month
 WHERE EXTRACT(YEAR FROM start_txn_time) = '2021' AND EXTRACT(MONTH FROM start_txn_time) = '01');
 ```
 
 ### High Level Sales Analysis
 ```TSQL
--What was the total quantity sold for all products?
--What is the total generated revenue for all products before discounts?
--What was the total discount amount for all products?

SELECT 
  SUM(qty) total_qty, 
  SUM(price*qty) total_revenue,
  ROUND(SUM((price*qty) * (discount::NUMERIC/100)),2) total_discount
FROM one_month_tbl;
```

| total_qty | total_revenue | total_discount |
|-----------|---------------|----------------|
| 14788     | 420672        | 51589.10       |

---

### Transaction Analysis

```TSQL
--How many unique transactions were there?
--What is the average unique products purchased in each transaction?
--What are the 25th, 50th and 75th percentile values for the revenue per transaction?
--What is the average discount value per transaction?

SELECT 
  COUNT(DISTINCT one_month_tbl.txn_id) unique_txn_count, 
  avg_prod_count,
  twenty_fifth_percentile,
  fifth_percentile,
  seventy_fifth_percentile,
  avg_discount
FROM 
  one_month_tbl,
  
  (WITH cte AS (
    SELECT txn_id, COUNT(DISTINCT prod_id) prod_count
    FROM one_month_tbl
    GROUP BY txn_id)

   SELECT ROUND(AVG(prod_count),2) avg_prod_count
   FROM cte) AS tmp,
   
   (WITH cte AS (
SELECT txn_id, ROUND(SUM((price * qty) * (1 - discount::NUMERIC/100)),2) revenue
FROM one_month_tbl
GROUP BY txn_id)

SELECT
  PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY revenue) twenty_fifth_percentile,
  PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY revenue) fifth_percentile,
  PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY revenue) seventy_fifth_percentile
FROM cte) AS tmp2,
  
  (WITH cte AS (
SELECT 
  txn_id, 
  ROUND(SUM((price*qty) * (discount::NUMERIC/100)),2) total_discount
FROM one_month_tbl
GROUP BY txn_id)

SELECT ROUND(AVG(total_discount),2) avg_discount
FROM cte) AS tmp3
GROUP BY 
  tmp.avg_prod_count, 
  tmp2.twenty_fifth_percentile, 
  tmp2.fifth_percentile, 
  tmp2.seventy_fifth_percentile,
  tmp3.avg_discount;
```

| unique_txn_count | avg_prod_count | twenty_fifth_percentile | fifth_percentile | seventy_fifth_percentile | avg_discount |
|------------------|----------------|-------------------------|------------------|--------------------------|--------------|
| 828              | 5.99           | 312.84                  | 434.07           | 563.58                   | 62.31        |


```TSQL
--What is the percentage split of all transactions for members vs non-members?
--What is the average revenue for member transactions and non-member transactions?

WITH cte AS (
SELECT 
  member, CAST(COUNT(DISTINCT txn_id)AS NUMERIC) txn_count
FROM one_month_tbl
GROUP BY member)

SELECT 
  cte.member, 
  ROUND(cte.txn_count/CAST(COUNT(DISTINCT one_month_tbl.txn_id)AS NUMERIC)*100, 1) txn_percentage
INTO tmp_tbl
FROM cte, one_month_tbl
GROUP BY cte.member, cte.txn_count;

WITH cte AS (
SELECT 
  member, 
  txn_id, 
  CAST(ROUND(SUM((price * qty) * (1 - discount::NUMERIC/100)),2)AS NUMERIC) revenue_per_txn
FROM one_month_tbl
GROUP BY 2,1)

SELECT
 (CASE WHEN cte.member = 'true' THEN 'member'
  ELSE 'non-member' END) AS status,
 txn_percentage, 
 ROUND(AVG(revenue_per_txn),2) avg_revenue
FROM cte
LEFT JOIN tmp_tbl ON cte.member=tmp_tbl.member
GROUP BY cte.member, txn_percentage;
```

| status     | txn_percentage | avg_revenue |
|------------|----------------|-------------|
| non-member | 	40.6           | 436.71      |
| member     | 	59.4           | 451.93      |

---

### Product Analysis

```TSQL
--What are the top 3 products by total revenue before discount?

WITH cte AS (
SELECT
  prod_id, SUM(qty) total_qty
FROM one_month_tbl
GROUP BY 1
)

SELECT cte.prod_id, product_name, (total_qty*s.price) total_revenue
FROM cte
LEFT JOIN one_month_tbl s ON cte.prod_id=s.prod_id
LEFT JOIN product_details pd ON cte.prod_id=pd.product_id
GROUP BY cte.prod_id, product_name, total_qty, s.price
ORDER BY total_revenue DESC
LIMIT 3;
```

| prod_id | product_name                 | total_revenue |
|---------|------------------------------|---------------|
| 9ec847  | Grey Fashion Jacket - Womens | 70200         |
| 2a2353  | Blue Polo Shirt - Mens       | 69198         |
| 5d267b  | White Tee Shirt - Mens       | 50240         |


```TSQL
--What is the total quantity, revenue and discount for each segment?
--What is the top selling product for each segment?
--What is the percentage split of revenue by segment for each category?

WITH cte AS (
SELECT
  prod_id,
  product_name,
  segment_id,
  segment_name,
  SUM(qty) total_qty
FROM one_month_tbl s
LEFT JOIN product_details pd ON s.prod_id=pd.product_id
GROUP BY 1,2,3,4),

cte2 AS (
SELECT 
  *,
  ROW_NUMBER() OVER(PARTITION BY segment_id ORDER BY total_qty DESC) row_n
FROM cte)

SELECT segment_name, product_name, total_qty
INTO tmp_tbl2
FROM cte2
WHERE row_n=1;

WITH cte AS (
SELECT 
  category_id, 
  category_name, 
  segment_id,
  segment_name,
  ROUND(SUM((s.price * s.qty) * (1 - discount::NUMERIC/100)),2) total_revenue
FROM one_month_tbl s
LEFT JOIN product_details pd ON s.prod_id=pd.product_id
GROUP BY 1,2,3,4)

SELECT
  segment_name,
  category_name,
  ROUND((total_revenue/SUM(total_revenue) OVER(PARTITION BY category_id))*100,1) percentage
INTO tmp_tbl4
FROM cte;

SELECT
  segment_id,
  pd.segment_name,
  SUM(qty) total_qty,
  ROUND(SUM((pd.price*qty) * (discount::NUMERIC/100)),2) total_discounts,
  ROUND(SUM((s.price * s.qty) * (1 - discount::NUMERIC/100)),2) total_revenue,
  tmp_tbl2.product_name top_selling_product, 
  tmp_tbl2.total_qty top_selling_product_qty,
  tmp_tbl4.category_name,
  percentage percentage_split_of_revenue
FROM one_month_tbl s
LEFT JOIN product_details pd ON s.prod_id=pd.product_id
LEFT JOIN tmp_tbl2 ON pd.segment_name=tmp_tbl2.segment_name
LEFT JOIN tmp_tbl4 ON pd.segment_name=tmp_tbl4.segment_name
GROUP BY 1, 2, tmp_tbl2.product_name, tmp_tbl2.total_qty, tmp_tbl4.category_name, tmp_tbl4.percentage;
```

| segment_id | segment_name | total_qty | total_discounts | total_revenue | top_selling_product          | top_selling_product_qty | category_name | percentage_split_of_revenue |
|------------|--------------|-----------|-----------------|---------------|------------------------------|-------------------------|---------------|-----------------------------|
| 3	          | Jeans        | 	3777      | 8482.68         | 60294.32	      | Cream Relaxed Jeans - Womens | 	1282	                    | Womens        | 	36.1                        |
| 4	          | Jacket       | 	3750      | 14871.38        | 106778.62	     | Grey Fashion Jacket - Womens | 	1300	                    | Womens        | 	63.9                        |
| 5	          | Shirt        | 	3690      | 16228.38        | 115409.62	     | White Tee Shirt - Mens       | 	1256	                    | Mens          | 	57.1                        |
| 6	          | Socks        | 	3571      | 12006.66        | 86600.34	      | Navy Solid Socks - Mens      | 	1264	                    | Mens          | 	42.9                        |

```TSQL
--What is the total quantity, revenue and discount for each category?
--What is the top selling product for each category?
--What is the percentage split of total revenue by category?

WITH cte AS (
SELECT
  prod_id,
  product_name,
  category_id,
  category_name,
  SUM(qty) total_qty
FROM one_month_tbl s
LEFT JOIN product_details pd ON s.prod_id=pd.product_id
GROUP BY 1,2,3,4),

cte2 AS (
SELECT 
  *,
  ROW_NUMBER() OVER(PARTITION BY category_id ORDER BY total_qty DESC) row_n
FROM cte)

SELECT category_name, product_name, total_qty
INTO tmp_tbl3
FROM cte2
WHERE row_n=1;

WITH cte AS (
SELECT 
  category_id, 
  category_name, 
  ROUND(SUM((s.price * s.qty) * (1 - discount::NUMERIC/100)),2) total_revenue
FROM one_month_tbl s
LEFT JOIN product_details pd ON s.prod_id=pd.product_id
GROUP BY 1,2)

SELECT 
  category_name,
  total_revenue,
  ROUND((total_revenue/SUM(total_revenue) OVER())*100,1) percentage
INTO tmp_tbl5
FROM cte
GROUP BY 1,2;

SELECT
  category_id,
  pd.category_name,
  SUM(qty) total_qty,
  ROUND(SUM((s.price * s.qty) * (1 - discount::NUMERIC/100)),2) total_revenue,
  ROUND(SUM((pd.price*qty) * (discount::NUMERIC/100)),2) total_discount,
  tmp_tbl3.product_name top_selling_product, 
  total_qty top_selling_product_qty,
  percentage percentage_split_of_revenue
FROM one_month_tbl s
LEFT JOIN product_details pd ON s.prod_id=pd.product_id
LEFT JOIN tmp_tbl3 ON pd.category_name=tmp_tbl3.category_name
LEFT JOIN tmp_tbl5 ON pd.category_name=tmp_tbl5.category_name
GROUP BY 1, 2, tmp_tbl3.product_name, tmp_tbl3.total_qty, tmp_tbl5.percentage
ORDER BY 1;
```

| category_id | category_name | total_qty | total_revenue | total_discount | top_selling_product          | top_selling_product_qty | percentage_split_of_revenue |
|-------------|---------------|-----------|---------------|----------------|------------------------------|-------------------------|-----------------------------|
| 1	           | Womens        | 	7527      | 167072.94     | 23354.06       | Grey Fashion Jacket - Womens | 	1300                    | 45.3                        |
| 2	           | Mens          | 	7261      | 202009.96     | 28235.04       | Navy Solid Socks - Mens      | 	1264                    | 54.7                        |

```TSQL
--What is the percentage split of revenue by product for each segment?
--What is the total transaction “penetration” for each product? 

SELECT
  product_name,
  n_sold AS n_items_sold,
  ROUND(100 * (n_sold::NUMERIC / total_transactions) ,2) AS penetration
INTO tmp_tbl6
FROM (SELECT pd.product_id,
             pd.product_name,
             COUNT(DISTINCT txn_id) AS n_sold,
             (SELECT COUNT(DISTINCT txn_id)
              FROM one_month_tbl) AS total_transactions
      FROM one_month_tbl AS s
      JOIN product_details pd ON s.prod_id=pd.product_id
      GROUP BY pd.product_id,
               pd.product_name) AS tmp
GROUP BY product_name, n_items_sold, penetration               
ORDER BY penetration DESC;

WITH cte AS (
SELECT 
  segment_id, 
  segment_name,
  product_id,
  product_name,
  ROUND(SUM((s.price * s.qty) * (1 - discount::NUMERIC/100)),2) total_revenue
FROM one_month_tbl s
LEFT JOIN product_details pd ON s.prod_id=pd.product_id
GROUP BY product_id, product_name, segment_id, segment_name)

SELECT
  segment_id, 
  segment_name,
  cte.product_name,
  total_revenue,
  ROUND((total_revenue/SUM(total_revenue) OVER(PARTITION BY segment_id))*100,1) percentage,
  n_items_sold,
  penetration penetration_percentage
FROM cte
LEFT JOIN tmp_tbl6 ON cte.product_name = tmp_tbl6.product_name;
```

| segment_id | segment_name | product_name                  | total_revenue | percentage | n_items_sold | penetration_percentage |
|------------|--------------|-------------------------------|---------------|------------|--------------|------------------------|
| 3	          | Jeans        | Cream Relaxed Jeans - Womens  | 	11224.20      | 18.6       | 432          | 52.17                  |
| 3	          | Jeans        | Black Straight Jeans - Womens | 	34752.96      | 57.6       | 408          | 49.28                  |
| 3	          | Jeans        | Navy Oversized Jeans - Womens | 	14317.16      | 23.7       | 423          | 51.09                  |
| 4	          | Jacket       | Indigo Rain Jacket - Womens   | 	20422.72      | 19.1       | 407          | 49.15                  |
| 4	          | Jacket       | Khaki Suit Jacket - Womens    | 	24736.50      | 23.2       | 402          | 48.55                  |


```TSQL
--What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
         
SELECT product_1,
	   product_2,
	   product_3,
	   times_bought_together
FROM (
		with products AS(
			SELECT txn_id,
				   product_name
			FROM one_month_tbl AS s
		    JOIN product_details AS pd ON s.prod_id = pd.product_id
		) 
		SELECT p.product_name AS product_1,
			   p1.product_name AS product_2,
			   p2.product_name AS product_3,
			   COUNT(*) AS times_bought_together,
			   ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) AS rank 
		FROM products AS p
			JOIN products AS p1 ON p.txn_id = p1.txn_id 
			AND p.product_name != p1.product_name 
			AND p.product_name < p1.product_name 
			JOIN products AS p2 ON p.txn_id = p2.txn_id
			AND p.product_name != p2.product_name 
			AND p1.product_name != p2.product_name 
			AND p.product_name < p2.product_name
			AND p1.product_name < p2.product_name
		GROUP BY p.product_name,
			p1.product_name,
			p2.product_name
	) AS tmp
WHERE RANK = 1;
```

| product_1                    | product_2                   | product_3              | times_bought_together |
|------------------------------|-----------------------------|------------------------|-----------------------|
| Grey Fashion Jacket - Womens | Teal Button Up Shirt - Mens | White Tee Shirt - Mens | 	125                   |
