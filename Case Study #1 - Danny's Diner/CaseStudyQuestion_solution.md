# 🍜 Case Study #1 - Danny's Diner

### ⚠️ Disclaimer

Some of the queries and Python codes might not return the exact same results. I made sure that they are at least very similar and answered the question.    
All the tables shown are actually the table markdown I made for my repository [8_Week_SQL_Challenge](https://github.com/KannaKit/8_Week_SQL_Challenge), therefore my python codes might show slightly different table if you try to run. 

### Import packages

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
```

### Reading in Files

Read files from the [case study](https://8weeksqlchallenge.com/case-study-1/).  
If you need guidance on reading files, I recommend watching this [video](https://www.youtube.com/watch?v=dUpyC40cF6Q&list=PLUaB-1hjhk8FE_XZ87vPPSfHqb6OcM0cF&index=53) I used to learn from. Shout out to [Alex the Analyst](https://www.youtube.com/@AlexTheAnalyst)👏

--- 

## Case Study Questions
### 1. What is the total amount each customer spent at the restaurant?
###### SQL

```TSQL
SELECT customer_id, sum(price) total_spent
FROM sales
LEFT JOIN menu
  ON sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY 1;
```

###### Python

```python
#left join sales & menu tables
sa_me = sales.merge(menu, how = 'left')

sum_per_customer = sa_me.groupby('customer_id')['price'].sum()
print(sum_per_customer)
```

customer_id	| total_spent
 --- | --- 
A|	76
B|	74
C|	36

###### Python Plot

```python
sum_per_customer.plot(kind = 'bar', title = 'Total $ Spent Per Customer')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_by_python/assets/106714718/3675f870-ba12-4907-b6a0-befce4dfe418" align="center" width="368" height="276" >

---

### 2. How many days has each customer visited the restaurant?
###### SQL

```TSQL
SELECT customer_id, COUNT(DISTINCT(order_date)) day_count
FROM sales
GROUP BY customer_id;
```

###### Python

```python
visit_n_per_customer = sa_me.groupby('customer_id')['order_date'].nunique()

print(visit_n_per_customer)
```

| customer_id | day_count |
|-------------|-----------|
| A           | 4         |
| B           | 6         |
| C           | 2         |

###### Python Plot

```python
visit_n_per_customer.plot(kind = 'bar', title = 'Visit Count Per Customer')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_by_python/assets/106714718/24a98d93-0f7f-4a76-af80-5755d45e2a98" align="center" width="362" height="276" >

---

### 3. What was the first item from the menu purchased by each customer?

I used DENSE_RANK here because order_date is not time stamped data so we wouldn't know which one is the first order if it's made on the same day.

###### SQL

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

###### Python

```python
s_rank = sa_me

s_rank['rank'] = sa_me.groupby('customer_id')['order_date'].rank(method='dense', ascending=True).astype(int)

first_item = s_rank[s_rank['rank'] == 1].sort_values(by='customer_id', ascending=True).drop_duplicates()

first_item[['customer_id', 'order_date', 'product_name']]
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
###### SQL

```TSQL
SELECT COUNT(s.product_id) AS most_purchased, product_name
FROM sales s
LEFT JOIN menu m
  ON s.product_id = m.product_id
GROUP BY s.product_id, m.product_name 
ORDER BY most_purchased DESC
LIMIT 1;
```

###### Python

```python
purchased_item_count = sa_me.groupby('product_name').size()

filtered_count = purchased_item_count[purchased_item_count.index.str.contains('ramen')]
print(filtered_count)
```

| most_purchased | product_name |
|-------------|-----------|
| 8          | ramen     |

---
### 5. Which item was the most popular for each customer?
###### SQL

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

###### Python

```python
# make a data frame for this question
popular = sa_me

# group by customer_id, product_id, product_name and count how many times ordered, alias the order count column
popular = popular.groupby(['customer_id','product_id', 'product_name']).agg({"order_date": "count"}).rename(columns={"order_date": "order_n"})

# rank by order count, partition by customer_id
popular['rank'] = popular.groupby(['customer_id'])['order_n'].rank(method='dense', ascending=False).astype(int)

# show only rank=1
popular[popular['rank'] == 1].sort_values(by='customer_id', ascending=True)
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
###### SQL

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

###### Python

```python
#merge sales, menu and members table, exclude customer who never became a member(=right join)
sa_me_me = sa_me.merge(members, how='right')

#filter out orders made before join_date
after_join = sa_me_me[sa_me_me['order_date']>=sa_me_me['join_date']]

# row_number() over (partition by customer_id order by order_date)
after_join['rank'] = after_join.groupby(['customer_id'])['order_date'].rank(method='dense', ascending=True).astype(int)

first_purchased = after_join[after_join['rank']==1]

first_purchased[['customer_id', 'product_name']]
```

| customer_id | product_name |
|-------------|-----------|
| A          | curry    |
| B          | sushi     |

---
### 7. Which item was purchased just before the customer became a member?
###### SQL

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

###### Python

```python
#merge sales, menu and members table, exclude customer who never became a member(=right join)
sa_me_me = sa_me.merge(members, how='right')

#filter out orders made after join_date
bef_join = sa_me_me[sa_me_me['order_date']<sa_me_me['join_date']]

# dense_rank() over (partition by customer_id order by order_date)
bef_join['rank'] = bef_join.groupby(['customer_id'])['order_date'].rank(method='dense', ascending=True).astype(int)

# determine max rank number for each customer
max_rank = bef_join.groupby(['customer_id']).agg({'rank':'max'}).rename(columns={"rank":"max_rank"})

# join tables
bef_join = bef_join.merge(max_rank, how = 'right', on='customer_id')

# search for orders rank = max rank
bef_join = bef_join[bef_join['rank']==bef_join['max_rank']]

bef_join[['customer_id', 'product_name']]
```

| customer_id | product_name |
|-------------|-----------|
| A          | sushi    |
| A          | curry    |
| B          | sushi     |

---
### 8. What is the total items and amount spent for each member before they became a member?
###### SQL

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

###### Python

```python
#filter out orders made after join_date
bef_join2 = sa_me_me[sa_me_me['order_date']<sa_me_me['join_date']]

bef_join2.groupby('customer_id').agg({'price':['count', 'sum']})
```

| customer_id | ordered_count | total_spent |
|-------------|---------------|-------------|
| A           | 2             | 25          |
| B           | 3             | 40          |

---
### 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
###### SQL

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

###### Python

```python
# copy sales and menu convined table
sa_me2 = sa_me

# create a point column, for now equall to price
sa_me2['point'] = sa_me2['price']

# 2 times more points to sushi order (CASE statement)
sa_me2['point'] = np.where(sa_me2['product_name']!='sushi', sa_me2['point']*10, sa_me2['point']*20)

# sum all the points per customer
point = sa_me2.groupby('customer_id')['point'].sum()

point
```

| customer_id | total_point |
|-------------|-------------|
| A           | 860         |
| B           | 940         |
| C           | 360         |

###### Python Plot

```python
point.plot(kind = 'bar', title = 'Total Point Per Customer')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_by_python/assets/106714718/3c66e6ff-58cb-4389-a884-1ab9d30a6489" align="center" width="375" height="276" >

---

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
###### SQL

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

###### Python

```python
# load timedelta package
from datetime import timedelta

# change join_date column to datetime
first_week['join_date'] = pd.to_datetime(first_week['join_date'])

#determine each customer's end date for bonus
first_week = sa_me_me
first_week['end_date'] = first_week['join_date'] + timedelta(days=6)

first_week['order_date'] = pd.to_datetime(first_week['order_date'])
first_week['end_date'] = pd.to_datetime(first_week['end_date'])

# 2 times more points to sushi order (CASE statement)
first_week['point'] = np.where((first_week['product_name']!='sushi') & (first_week['order_date'] < first_week['join_date']), first_week['price']*10, 
                      np.where((first_week['product_name']=='sushi') & (first_week['order_date'] < first_week['join_date']), first_week['price']*20,
                      np.where((first_week['order_date'] >= first_week['join_date']) & (first_week['order_date'] <= first_week['end_date']), first_week['price']*20, first_week['price']*10)))

# exclude order after 2021-02-01
point2 = first_week[first_week.order_date < '2021-02-01']

# sum up point for each customer
point2 = point2.groupby('customer_id')['point'].sum()

point2
```

| customer_id | total_point |
|-------------|-------------|
| A           | 1370         |
| B           | 820         |

###### Python Plot

```python
point2.plot(kind = 'bar', title = 'Total Point Per Customer')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_by_python/assets/106714718/aa5af45b-0f9b-414b-bb5d-d8dbcb033471" align="center" width="381" height="276" >

