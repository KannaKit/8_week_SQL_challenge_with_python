# 🏦 Case Study #4 - Data Bank
### ⚠️ Disclaimer

Some of the queries and Python codes might return different results. I ensured they were at least very similar and answered the question.    
All the tables shown are actually the table markdown I made for my repository [8_Week_SQL_Challenge](https://github.com/KannaKit/8_Week_SQL_Challenge), therefore my Python codes might show slightly different table if you try to run. 

### Import packages

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
```

### Reading in Files

Read files from the [case study](https://8weeksqlchallenge.com/case-study-4/).  
If you need guidance on reading files, I recommend watching this [video](https://www.youtube.com/watch?v=dUpyC40cF6Q&list=PLUaB-1hjhk8FE_XZ87vPPSfHqb6OcM0cF&index=53) I used to learn from. Shout out to [Alex the Analyst](https://www.youtube.com/@AlexTheAnalyst)👏

--- 

## 🧹 Quick Data Cleaning 
###### Python

```python
# check how many of data in end_date start with '2020'
clean = nodes.end_date.str.startswith('2020').reset_index()

clean.groupby('end_date').count()
```

| end_date | index |
|----------|-------|
| False    | 500   |
| True     | 3000  |

```python
# check how many of data in end_date start with '9999'
outlier = nodes.end_date.str.startswith('9999').reset_index()

outlier.groupby('end_date').count()

# all the data which don't start with '2020' start with '9999'
```

| end_date | index |
|----------|-------|
| False    | 3000   |
| True     | 500  |

```python
# check how many of data in end_date start with '9999' but not '9999-12-31'
nodes[(nodes['end_date'].str.startswith('9999')) & (nodes['end_date']!='9999-12-31')]

# there's no such data
# I will drop all the rows with end_date '9999-12-31'

nodes2 = nodes[~nodes['end_date'].str.startswith('9999')]

nodes2['start_date'] = pd.to_datetime(nodes2.start_date)
nodes2['end_date'] = pd.to_datetime(nodes2.end_date)
```

--- 

## 👩‍💻 A. Customer Nodes Exploration
### 1. How many unique nodes are there on the Data Bank system?
###### SQL

```TSQL
SELECT COUNT(DISTINCT node_id)
FROM customer_nodes;
```

###### Python

```python
nodes.node_id.nunique()
```

| count | 
|-------------|
| 5  	           | 

---

### 2. What is the number of nodes per region?
###### SQL

```TSQL
SELECT region_name, COUNT(node_id)
FROM customer_nodes c
JOIN regions r ON c.region_id=r.region_id
GROUP BY region_name;
```

###### Python

```python
merged_df = nodes.merge(regions, how='inner')

result_df = merged_df.groupby('region_name')['node_id'].count().reset_index(name='node_count')

result_df
```

| region_name | count |
|----------------|----------------|
| America              | 735             |
| Australia              | 770             |
| Africa              | 714             |
| Asia              | 665             |
| Europe              | 616             |

###### Python Plot

```python
result_df.plot(kind='bar', x='region_name', title='Number of Nodes Per Regions')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/c9b6eb4e-d5f4-4943-8ed8-61f4312ec7f5" align="center" width="375" height="314" >

---

### 3. How many customers are allocated to each region?
###### SQL

```TSQL
SELECT region_name, COUNT(DISTINCT customer_id)
FROM customer_nodes c
JOIN regions r ON c.region_id=r.region_id
GROUP BY region_name;
```

###### Python

```python
result_df = merged_df.groupby('region_name')['customer_id'].nunique().reset_index(name='customer_count')

result_df
```

| region_name | count |
|----------------|----------------|
| America              | 102             |
| Australia              | 105             |
| Africa              | 95             |
| Asia              | 110             |
| Europe              | 88             |

###### Python Plot

```python
result_df.plot(kind='bar', x='region_name', title='Number of Customers Per Regions')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/85f2b8fe-1252-46e2-95fb-235302d83195" align="center" width="375" height="314" >

---

### 4. How many days on average are customers reallocated to a different node?
###### SQL

```TSQL
WITH cte AS (
 SELECT customer_id, (end_date-start_date) start_to_end
 FROM customer_nodes
 WHERE EXTRACT(YEAR FROM end_date) != 9999)
 
SELECT ROUND(AVG(start_to_end),1) avg_period
FROM cte;
```

###### Python

```python
(nodes2.end_date-nodes2.start_date).mean()
```

| avg_period     | 
|---------------|
| 14.6        |

---

### 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
###### SQL

```TSQL
WITH cte AS (
 SELECT 
   customer_id, 
   (end_date-start_date) start_to_end,
   region_name
 FROM customer_nodes c
  JOIN regions r ON c.region_id=r.region_id
 WHERE EXTRACT(YEAR FROM end_date) != 9999)
 
SELECT
 region_name,
 PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY start_to_end) median,
 PERCENTILE_DISC(0.8) WITHIN GROUP (ORDER BY start_to_end) eightieth_percentile,
 PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY start_to_end) ninety_fifth_percentile
FROM cte
GROUP BY region_name;
```

###### Python

```python
df = nodes2

df['start_to_end']=df.end_date-df.start_date

merged_df = df.merge(regions, how='inner')

median_df = merged_df.groupby('region_name')['start_to_end'].quantile(.5).reset_index(name='median')
q85_df = merged_df.groupby('region_name')['start_to_end'].quantile(.8).reset_index(name='eightieth_percentile')
q95_df = merged_df.groupby('region_name')['start_to_end'].quantile(.95).reset_index(name='ninety_fifth_percentile')

merged_df = median_df.merge(q85_df, how='inner')
merged_df = merged_df.merge(q95_df, how='inner')

merged_df
```

| region_name | median | eightieth_percentile | ninety_fifth_percentile |
|-------------|--------|----------------------|-------------------------|
| Africa      | 	15     | 24                   | 28                      |
| America     | 	15     | 23                   | 28                      |
| Asia        | 	15     | 23                   | 28                      |
| Australia   | 	15     | 23                   | 28                      |
| Europe      | 	15     | 24                   | 28                      |

> `percentile_disc` will return a value from the input set closest to the percentile you request.
>> meaning if median was chosen from [1,2,4,5] then it will return 5. 
>
> `percentile_cont` will return an interpolated value between multiple values based on the distribution. You can think of this as being more accurate, but can return a fractional value between the two values from the input
>> meaning if median was chosen from [1,2,4,5] then it will return 3. 
