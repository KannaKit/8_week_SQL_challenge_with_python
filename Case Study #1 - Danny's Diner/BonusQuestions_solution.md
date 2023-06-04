# 🍜 Case Study #1 - Danny's Diner


### ⚠️ Disclaimer

Some of the queries and Python codes might not return the exact same results. I made sure that they are at least very similar and answered the question.    
All the tables shown are actually the table markdown I made for my repository [8_Week_SQL_Challenge](https://github.com/KannaKit/8_Week_SQL_Challenge), therefore my python codes might show slightly different table if you try to run. 

I might be using dataframe from the Case Study Questions. Please refer to [this](https://github.com/KannaKit/8_week_SQL_challenge_by_python/blob/main/Case%20Study%20%231%20-%20Danny's%20Diner/CaseStudyQuestion_solution.md#2-how-many-days-has-each-customer-visited-the-restaurant). 

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

###### SQL

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

###### Python

```python
# join all 3 tables
join_df = sa_me.merge(members, how='left')

# add member column
join_df['member'] = np.where((join_df['join_date'].isna()) | (join_df['order_date'] < join_df['join_date']), 'N', 'Y') 

# select relevant columns
join_df[['customer_id', 'order_date', 'product_name', 'price', 'member']]
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

###### SQL

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

###### Python

```python
# copy df from previous question
join_df2 = join_df

# filter out member == N and put rank on wherever member column is Y
# and add fill na with 'null' 
join_df2['ranking'] = join_df2[join_df2['member'] == 'Y'].groupby(['customer_id'])['order_date'].rank(method='dense', ascending=True).astype(int).astype(str)
join_df2['ranking'] = join_df2['ranking'].fillna('null').astype(str)

# select relevant columns
join_df[['customer_id', 'order_date', 'product_name', 'price', 'member', 'ranking']]
```

###### Python (method 2)

```python
df = join_df

# using np.where
df['ranking'] = np.where((df['member'] == 'N'), 'null', 
                         df.groupby(['customer_id', 'member'])['order_date'].rank(method='dense', ascending=True).astype(int))

# select relevant columns
df[['customer_id', 'order_date', 'product_name', 'price', 'member', 'ranking']]
```

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
