# 🌄 Case Study #7 - Balanced Tree Clothing Co.
## 👕 Product Analysis
### 1. What are the top 3 products by total revenue before discount?
###### SQL

```TSQL
WITH cte AS (
SELECT
  prod_id, SUM(qty) total_qty
FROM sales
GROUP BY 1
)

SELECT cte.prod_id, product_name, (total_qty*s.price) total_revenue
FROM cte
LEFT JOIN sales s ON cte.prod_id=s.prod_id
LEFT JOIN product_details pd ON cte.prod_id=pd.product_id
GROUP BY cte.prod_id, product_name, total_qty, s.price
ORDER BY total_revenue DESC
LIMIT 3;
```

###### Python

```python
df=sales

df = df.groupby('prod_id', as_index=False)['qty'].sum()

df=df.merge(details, how='inner', left_on='prod_id', right_on='product_id')

df['total_revenue']=df.qty*df.price

df[['prod_id', 'product_name', 'total_revenue']].sort_values('total_revenue', ascending=False).head(3)
```

| prod_id | product_name                 | total_revenue |
|---------|------------------------------|---------------|
| 2a2353  | Blue Polo Shirt - Mens       | 217683        |
| 9ec847  | Grey Fashion Jacket - Womens | 209304        |
| 5d267b  | White Tee Shirt - Mens       | 152000        |

---

### 2. What is the total quantity, revenue and discount for each segment?
###### SQL

```TSQL
SELECT
  segment_id,
  segment_name,
  SUM(qty) total_qty,
  ROUND(SUM((pd.price*qty) * (discount::NUMERIC/100)),2) total_discounts,
  ROUND(SUM((s.price * s.qty) * (1 - discount::NUMERIC/100)),2) total_revenue
FROM sales s
LEFT JOIN product_details pd ON s.prod_id=pd.product_id
GROUP BY 1,2;
```

###### Python

```python
df=sales.merge(details, how='left', left_on='prod_id', right_on='product_id')

df['discount_price']=df.qty*df.price_x*(df.discount/100)
df['revenue']=df.qty*df.price_x*(1-df.discount/100)

df.groupby(['segment_id', 'segment_name']).agg({'qty':['sum'], 'discount_price':['sum'], 'revenue':['sum']})
```

| segment_id | segment_name | total_qty | total_discounts | total_revenue |
|------------|--------------|-----------|-----------------|---------------|
| 4	          | Jacket       | 	11385     | 44277.46        | 322705.54     |
| 6	          | Socks        | 	11217     | 37013.44        | 270963.56     |
| 5	          | Shirt        | 	11265     | 49594.27        | 356548.73     |
| 3	          | Jeans        | 	11349     | 25343.97        | 183006.03     |

---

### 3. What is the top selling product for each segment?
###### SQL

```TSQL
WITH cte AS (
SELECT
  prod_id,
  product_name,
  segment_id,
  segment_name,
  SUM(qty) total_qty
FROM sales s
LEFT JOIN product_details pd ON s.prod_id=pd.product_id
GROUP BY 1,2,3,4),

cte2 AS (
SELECT 
  *,
  ROW_NUMBER() OVER(PARTITION BY segment_id ORDER BY total_qty DESC) row_n
FROM cte)

SELECT segment_name, product_name, total_qty
FROM cte2
WHERE row_n=1;
```

###### Python

```python
df=df.groupby(['segment_id', 'segment_name', 'product_name'], as_index=False)['qty'].sum()

df['rank'] = df.sort_values(['segment_id', 'qty'], ascending=[True, False])\
                .groupby('segment_id')['qty'].rank(method='first').astype(int)

df[df['rank']==3]
```

| segment_name | product_name                  | total_qty |
|--------------|-------------------------------|-----------|
| Jeans        | Navy Oversized Jeans - Womens | 	3856      |
| Jacket       | Grey Fashion Jacket - Womens  | 	3876      |
| Shirt        | Blue Polo Shirt - Mens        | 	3819      |
| Socks        | Navy Solid Socks - Mens       | 	3792      |

---

### 4. What is the total quantity, revenue and discount for each category?
###### SQL

```TSQL
SELECT
  category_id,
  category_name,
  SUM(qty) total_qty,
  ROUND(SUM((s.price * s.qty) * (1 - discount::NUMERIC/100)),2) total_revenue,
  ROUND(SUM((pd.price*qty) * (discount::NUMERIC/100)),2) total_discount
FROM sales s
LEFT JOIN product_details pd ON s.prod_id=pd.product_id
GROUP BY 1,2
ORDER BY 1;
```

###### Python

```python
df=sales.merge(details, how='left', left_on='prod_id', right_on='product_id')

df['discount_price']=df.qty*df.price_x*(df.discount/100)
df['revenue']=df.qty*df.price_x*(1-df.discount/100)

df.groupby(['category_id', 'category_name']).agg({'qty':['sum'], 'discount_price':['sum'], 'revenue':['sum']})
```

| category_id | category_name | total_qty | total_revenue | total_discount |
|-------------|---------------|-----------|---------------|----------------|
| 1	           | Womens        | 	22734     | 505711.57     | 69621.43       |
| 2	           | Mens          | 	22482     | 627512.29     | 86607.71       |

---

### 5. What is the top selling product for each category?
###### SQL

```TSQL
WITH cte AS (
SELECT
  prod_id,
  product_name,
  category_id,
  category_name,
  SUM(qty) total_qty
FROM sales s
LEFT JOIN product_details pd ON s.prod_id=pd.product_id
GROUP BY 1,2,3,4),

cte2 AS (
SELECT 
  *,
  ROW_NUMBER() OVER(PARTITION BY category_id ORDER BY total_qty DESC) row_n
FROM cte)

SELECT category_name, product_name, total_qty
FROM cte2
WHERE row_n=1;
```

###### Python

```python
df=df.groupby(['category_id', 'category_name', 'product_name'], as_index=False)['qty'].sum()

df['rank'] = df.sort_values(['category_id', 'qty'], ascending=[True, False])\
               .groupby(['category_id', 'category_name'])['qty'].rank(method='first', ascending=False).astype(int)

df[df['rank']==1]
```

| category_name | product_name                 | total_qty |
|---------------|------------------------------|-----------|
| Womens        | Grey Fashion Jacket - Womens | 	3876      |
| Mens          | Blue Polo Shirt - Mens       | 	3819      |

---

### 6. What is the percentage split of revenue by product for each segment?
###### SQL

```TSQL
WITH cte AS (
SELECT 
  segment_id, 
  segment_name,
  product_id,
  product_name,
  ROUND(SUM((s.price * s.qty) * (1 - discount::NUMERIC/100)),2) total_revenue
FROM sales s
LEFT JOIN product_details pd ON s.prod_id=pd.product_id
GROUP BY product_id, product_name, segment_id, segment_name)

SELECT
  segment_id, 
  segment_name,
  product_name,
  total_revenue,
  ROUND((total_revenue/SUM(total_revenue) OVER(PARTITION BY segment_id))*100,1) percentage
FROM cte;
```

###### Python

```python
df=sales.merge(details, how='left', left_on='prod_id', right_on='product_id')

df['revenue']=df.qty*df.price_x*(1-df.discount/100)

df=df.groupby(['segment_id', 'segment_name', 'product_name'], as_index=False)['revenue'].sum()

seg_revenue=df.groupby('segment_id', as_index=False)['revenue'].sum()

df=df.merge(seg_revenue, on='segment_id', how='left')

df['percentage']=100*df.revenue_x/df.revenue_y

df=df[['segment_id', 'segment_name', 'product_name', 'revenue_x', 'percentage']]

df = df.rename({'revenue_x': 'total_revenue'}, axis=1)
```

First 5 rows.

| segment_id | segment_name | product_name                  | total_revenue | percentage |
|------------|--------------|-------------------------------|---------------|------------|
| 3	          | Jeans        | Navy Oversized Jeans - Womens | 	43992.39      | 24.0       |
| 3	          | Jeans        | Black Straight Jeans - Womens | 	106407.04     | 58.1       |
| 3	          | Jeans        | Cream Relaxed Jeans - Womens  | 	32606.60      | 17.8       |
| 4	          | Jacket       | Indigo Rain Jacket - Womens   | 	62740.47      | 19.4       |
| 4	          | Jacket       | Khaki Suit Jacket - Womens    | 	76052.95      | 23.6       |

---

### 7. What is the percentage split of revenue by segment for each category?
###### SQL

```TSQL
WITH cte AS (
SELECT 
  category_id, 
  category_name, 
  segment_id,
  segment_name,
  ROUND(SUM((s.price * s.qty) * (1 - discount::NUMERIC/100)),2) total_revenue
FROM sales s
LEFT JOIN product_details pd ON s.prod_id=pd.product_id
GROUP BY 1,2,3,4)

SELECT
  segment_name,
  category_name,
  ROUND((total_revenue/SUM(total_revenue) OVER(PARTITION BY category_id))*100,1) percentage
FROM cte;
```

###### Python

```python
df=sales.merge(details, how='left', left_on='prod_id', right_on='product_id')

df['revenue']=df.qty*df.price_x*(1-df.discount/100)

df=df.groupby(['category_id', 'category_name', 'segment_name'])['revenue'].sum().reset_index(name='total_revenue')

cat_revenue=df.groupby('category_id')['total_revenue'].sum().reset_index(name='category_revenue')

df=df.merge(cat_revenue, on='category_id', how='left')

df['percentage']=100*df.total_revenue/df.category_revenue

df[['category_id', 'category_name', 'segment_name', 'total_revenue', 'percentage']]
```

| segment_name | category_name | percentage |
|--------------|---------------|------------|
| Jacket       | Womens        | 	63.8       |
| Jeans        | Womens        | 	36.2       |
| Shirt        | Mens          | 	56.8       |
| Socks        | Mens          | 	43.2       |

---

### 8. What is the percentage split of total revenue by category?
###### SQL

```TSQL
WITH cte AS (
SELECT 
  category_id, 
  category_name, 
  ROUND(SUM((s.price * s.qty) * (1 - discount::NUMERIC/100)),2) total_revenue
FROM sales s
LEFT JOIN product_details pd ON s.prod_id=pd.product_id
GROUP BY 1,2)

SELECT 
  category_name,
  total_revenue,
  ROUND((total_revenue/SUM(total_revenue) OVER())*100,1) percentage
FROM cte
GROUP BY 1,2;
```

###### Python

```python
df=sales.merge(details, how='left', left_on='prod_id', right_on='product_id')

df['revenue']=df.qty*df.price_x*(1-df.discount/100)

df=df.groupby(['category_id', 'category_name'])['revenue'].sum().reset_index(name='total_revenue')

df['percentage']=100*df.total_revenue/df.total_revenue.sum()

df[['category_id', 'category_name', 'total_revenue', 'percentage']]
```

| category_name | category_name | percentage |
|--------------|---------------|------------|
| Mens          | 	627512.29       | 55.4 |
| Womens        | 	505711.57       | 44.6 |

---

### 9. What is the total transaction “penetration” for each product? 
(hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

###### SQL

```TSQL
SELECT
  product_name,
  n_sold AS n_items_sold,
  ROUND(100 * (n_sold::NUMERIC / total_transactions) ,2) AS penetration
FROM (SELECT pd.product_id,
             pd.product_name,
             COUNT(DISTINCT txn_id) AS n_sold,
             (SELECT COUNT(DISTINCT txn_id)
              FROM sales) AS total_transactions
      FROM sales AS s
      JOIN product_details pd ON s.prod_id=pd.product_id
      GROUP BY pd.product_id,
               pd.product_name) AS tmp
GROUP BY product_name, n_items_sold, penetration               
ORDER BY penetration DESC;
```

###### Python

```python
total_txn = sales['txn_id'].nunique()

df=sales

df = df.groupby('prod_id')['txn_id'].count().reset_index(name='n_sold')

df['penetration']=100*df.n_sold/total_txn

df=df.merge(details, left_on='prod_id', right_on='product_id', how='left')

df[['product_name', 'penetration']]
```

First 5 rows.

| product_name                  | n_items_sold | penetration |
|-------------------------------|--------------|-------------|
| Navy Solid Socks - Mens       | 	1281         | 51.24       |
| Grey Fashion Jacket - Womens  | 	1275         | 51.00       |
| Navy Oversized Jeans - Womens | 	1274         | 50.96       |
| Blue Polo Shirt - Mens        | 	1268         | 50.72       |
| White Tee Shirt - Mens        | 	1268         | 50.72       |

---

### 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

For this question I refered to [this](https://github.com/iweld/8-Week-SQL-Challenge/blob/main/Case%20Study%207%20-%20Balanced%20Tree/questions_and_answers.md)

###### SQL

```TSQL
-- Select the 3 item combination and the count of the amount of times items where bought together.
SELECT product_1,
	   product_2,
	   product_3,
	   times_bought_together
FROM (
		-- Create a CTE that joins the Sales table with the Product Details table and gather the
		-- transaction id's and product names.
		with products AS(
			SELECT txn_id,
				   product_name
			FROM sales AS s
		    JOIN product_details AS pd ON s.prod_id = pd.product_id
		) -- Use self-joins to create every combination of products.  Each column is derived from its own table.
		SELECT p.product_name AS product_1,
			   p1.product_name AS product_2,
			   p2.product_name AS product_3,
			   COUNT(*) AS times_bought_together,
			   ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) AS rank -- Use a window function to apply a unique row number to each permutation.
		FROM products AS p
			JOIN products AS p1 ON p.txn_id = p1.txn_id -- Self-join table 1 to table 2
			AND p.product_name != p1.product_name -- Ensure that we DO NOT duplicate items.
			AND p.product_name < p1.product_name -- Self-join table 1 to table 3
			JOIN products AS p2 ON p.txn_id = p2.txn_id
			AND p.product_name != p2.product_name -- Ensure that we DO NOT duplicate items in the first table.
			AND p1.product_name != p2.product_name -- Ensure that we DO NOT duplicate items in the second table.
			AND p.product_name < p2.product_name
			AND p1.product_name < p2.product_name
		GROUP BY p.product_name,
			p1.product_name,
			p2.product_name
	) AS tmp
WHERE RANK = 1;
-- Filter only the highest ranking item.
```

###### Python

```python
# list up all possible combinations of product_id
combinations = list(itertools.combinations(details.product_id, 3))

# make the result a dataframe
all_combo = pd.DataFrame(combinations)
# change column names
all_combo.columns=['prod1', 'prod2', 'prod3']

df=sales

# find what was purchased together
df['bought_together']=df.groupby('txn_id')['prod_id'].transform(lambda x: ', '.join(x))

df=df.drop_duplicates(subset=['txn_id'])

# filter out single product order and 2 products order
# count comma, 2 commas mean there are 3 items bought together
df['comma_count']=df.bought_together.str.count(', ')
df=df[df['comma_count']>=2]

#keep only relavent column
df=df[['bought_together']]

matching_combinations = {}

for i in all_combo.index:
    combination = (all_combo['prod1'].iloc[i], all_combo['prod2'].iloc[i], all_combo['prod3'].iloc[i])
    matching_rows = df['bought_together'].str.contains(combination[0]) & df['bought_together'].str.contains(combination[1]) & df['bought_together'].str.contains(combination[2])
    count = matching_rows.sum()
    matching_combinations[combination] = count

# Convert the matching_combinations dictionary to a DataFrame
result_df = pd.DataFrame(list(matching_combinations.items()), columns=['Combination', 'Match Count'])

# Sort the DataFrame by 'Match Count' column in descending order
result_df = result_df.sort_values(by='Match Count', ascending=False)

# Get the most matched combination
most_matched_combination = result_df.iloc[0, 0]

# Create a new DataFrame with the values in separate columns
most_matched_df = pd.DataFrame([most_matched_combination], columns=['Product1', 'Product2', 'Product3'])

most_matched_df = most_matched_df.merge(details, how='inner', left_on='Product1', right_on='product_id')
most_matched_df = most_matched_df.merge(details, how='inner', left_on='Product2', right_on='product_id')
most_matched_df = most_matched_df.merge(details, how='inner', left_on='Product3', right_on='product_id')

most_matched_df[['product_name_x', 'product_name_y', 'product_name']]
```

| product_1                    | product_2                   | product_3              | times_bought_together |
|------------------------------|-----------------------------|------------------------|-----------------------|
| Grey Fashion Jacket - Womens | Teal Button Up Shirt - Mens | White Tee Shirt - Mens | 	352                   |
