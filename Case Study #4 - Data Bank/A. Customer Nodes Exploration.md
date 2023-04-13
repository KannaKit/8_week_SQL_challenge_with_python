# 🏦 Case Study #4 - Data Bank
## 👩‍💻 A. Customer Nodes Exploration
### 1. How many unique nodes are there on the Data Bank system?

```TSQL
SELECT COUNT(DISTINCT node_id)
FROM customer_nodes;
```

| count | 
|-------------|
| 5  	           | 

---

### 2. What is the number of nodes per region?

```TSQL
SELECT region_name, COUNT(node_id)
FROM customer_nodes c
JOIN regions r ON c.region_id=r.region_id
GROUP BY region_name;
```

First 5 rows.

| region_name | count |
|----------------|----------------|
| America              | 735             |
| Australia              | 770             |
| Africa              | 714             |
| Asia              | 665             |
| Europe              | 616             |

---

### 3. How many customers are allocated to each region?

```TSQL
SELECT region_name, COUNT(DISTINCT customer_id)
FROM customer_nodes c
JOIN regions r ON c.region_id=r.region_id
GROUP BY region_name;
```

| region_name | count |
|----------------|----------------|
| America              | 102             |
| Australia              | 105             |
| Africa              | 95             |
| Asia              | 110             |
| Europe              | 88             |

---

### 4. How many days on average are customers reallocated to a different node?

```TSQL
WITH cte AS (
 SELECT customer_id, (end_date-start_date) start_to_end
 FROM customer_nodes
 WHERE EXTRACT(YEAR FROM end_date) != 9999)
 
SELECT ROUND(AVG(start_to_end),1) avg_period
FROM cte;
```

| avg_period     | 
|---------------|
| 14.6        |

---

### 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

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
