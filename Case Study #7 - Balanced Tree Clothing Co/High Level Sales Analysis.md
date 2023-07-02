# 🌄 Case Study #7 - Balanced Tree Clothing Co.
### ⚠️ Disclaimer

Some of the queries and Python codes might return different results. I ensured they were at least very similar and answered the question.    
All the tables shown are actually the table markdown I made for my repository [8_Week_SQL_Challenge](https://github.com/KannaKit/8_Week_SQL_Challenge), therefore my Python codes might show slightly different table if you try to run. 

### Import packages

```python
import pandas as pd
import numpy as np
import itertools
```

### Reading in Files

Read files from the [case study](https://8weeksqlchallenge.com/case-study-7/).  
If you need guidance on reading files, I recommend watching this [video](https://www.youtube.com/watch?v=dUpyC40cF6Q&list=PLUaB-1hjhk8FE_XZ87vPPSfHqb6OcM0cF&index=53) I used to learn from. Shout out to [Alex the Analyst](https://www.youtube.com/@AlexTheAnalyst)👏

## 👩‍💻 High Level Sales Analysis
### 1. What was the total quantity sold for all products?
###### SQL

```TSQL
SELECT SUM(qty) total_qty
FROM sales;
```

###### Python

```python
sales['qty'].sum()
```

| total_qty  | 
|------------|
| 45216 |

---

### 2. What is the total generated revenue for all products before discounts?
###### SQL

```TSQL
SELECT SUM(price*qty) total_revenue
FROM sales;
```

###### Python

```python
df = sales
df['revenue'] = df.price*df.qty
df.revenue.sum()
```

| total_revenue  | 
|------------|
| 1289453 |

---

### 3. What was the total discount amount for all products?
###### SQL

```TSQL
SELECT ROUND(SUM((price*qty) * (discount::NUMERIC/100)),2) total_discount
FROM sales;
```

###### Python

```python
df['discounted'] = df.price*df.qty*(df.discount/100)
df.discounted.sum()
```

| total_discount  | 
|------------|
| 156229.14 | 
