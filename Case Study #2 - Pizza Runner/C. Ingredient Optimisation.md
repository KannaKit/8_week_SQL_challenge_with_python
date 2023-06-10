# 🍕 Case Study #2 - Pizza Runner
## 👩‍🍳 C. Ingredient Optimisation
### 1. What are the standard ingredients for each pizza?

I had to do extra data cleaning in order to answer this question.

###### SQL

```TSQL
--Normalize a table
DROP TABLE IF EXISTS pizza_recipes1;
CREATE TABLE pizza_recipes1 AS
(SELECT pizza_id, unnest(string_to_array(toppings, ' ')) topping
FROM   pizza_recipes);

UPDATE pizza_recipes1
SET topping = CASE WHEN topping LIKE '%,' THEN LEFT(topping, LENGTH(topping)-1)
                   ELSE topping
              END;

ALTER TABLE pizza_recipes1
ALTER COLUMN topping TYPE INT
USING (trim(topping)::INT);
```

###### Python

```python
# copy a table
df = pizza_recipes

# normalize a table
# split toppings column by comma, and stack them up
# rename column
# get rid of comma (regex=regular expressions)
# reset index
result_df = df.apply(lambda x: pd.Series(x['toppings'].split(' ')), axis=1).stack().rename('topping').replace(',','', regex=True).reset_index(level=1, drop=True)
```

Now, the new table `pizza_recipes1` looks like this. (First 10 lines)

| pizza_id | topping |
|----------|---------|
| 1        | 2       |
| 1        | 3       |
| 1        | 4       |
| 1        | 5       |
| 1        | 6       |
| 1        | 8       |
| 1        | 10      |
| 2        | 4       |
| 2        | 6       |

###### SQL

```TSQL
WITH cte AS (SELECT pizza_name, pr.pizza_id, topping_name
             FROM pizza_names pn
             INNER JOIN pizza_recipes1 pr ON pn.pizza_id=pr.pizza_id
             INNER JOIN pizza_toppings pt ON pr.topping=pt.topping_id
             order by pizza_name, pr.pizza_id)

select pizza_name, string_agg(topping_name, ', ') as standard_toppings
from cte
group by pizza_name;
FROM cte;
```

###### Python

```python
# concat pizza_id and topping columns 
concat_df = pd.concat([df['pizza_id'], result_df], axis=1)

# change data type for topping column to integer
concat_df['topping'] = concat_df['topping'].astype(int)

# join tables
merged_df = concat_df.merge(pizza_toppings, how='left', left_on='topping', right_on='topping_id')
merged_df = merged_df.merge(pizza_names, how='left', on='pizza_id')

# reshape the table
merged_df.groupby('pizza_name', as_index=False)[['topping_name']]\
          .agg(lambda x: ', '.join(map(str,set(x))))
```

| pizza_name | standard_toppings                                              |
|------------|----------------------------------------------------------------|
| Meatlovers | BBQ Sauce, Pepperoni, Cheese, Salami, Chicken, Bacon, Mushrooms, Beef |
| Vegetarian | Tomato Sauce, Cheese, Mushrooms, Onions, Peppers, Tomatoes          |

---

### 2. What was the most commonly added extra?

And, more unnesting columns...

###### SQL

```TSQL
DROP TABLE IF EXISTS customer_orders2;
CREATE TABLE customer_orders2 AS (
	SELECT 
    order_id, 
    customer_id, 
    pizza_id, 
    unnest(string_to_array(exclusions, ' ')) exclusions1, 
    unnest(string_to_array(extras, ' ')) extras1, 
    order_time
  FROM customer_orders1);

--TRIM commas, change empty string & 'null' to NULL 
UPDATE customer_orders2
SET extras1 = 
	CASE WHEN extras1 LIKE '%,' THEN TRIM(LEFT(extras1, LENGTH(extras1)-1))
		   WHEN extras1 IS NULL THEN NULL
       WHEN extras1 = '' THEN NULL
		   WHEN extras1 = 'null' THEN NULL
  ELSE extras1 END,
    exclusions1 = 
	CASE WHEN exclusions1 LIKE '%,' THEN TRIM(LEFT(exclusions1, LENGTH(exclusions1)-1))
       WHEN exclusions1 IS NULL THEN NULL
			 WHEN exclusions1 = '' THEN NULL
			 WHEN exclusions1 = 'null' THEN NULL
  ELSE exclusions1 END;
              
--Change data type to integar
ALTER TABLE customer_orders2
ALTER COLUMN extras1 TYPE INT
USING extras1::INT,
ALTER COLUMN exclusions1 TYPE INT
USING exclusions1::INT;
```

Now, the new table `customer_orders2` looks like this. (First 4 lines)

| order_id | customer_id | pizza_id | exclusions1 | extras1 | order_time          |
|----------|-------------|----------|-------------|---------|---------------------|
| 4        | 103         | 1        | 4           |         | 2020-01-04 13:23:46 |
| 4        | 103         | 1        | 4           |         | 2020-01-04 13:23:46 |
| 4        | 103         | 2        | 4           |         | 2020-01-04 13:23:46 |
| 5        | 104         | 1        | 1           | 1       | 2020-01-08 21:00:29 |

```TSQL
SELECT topping_name, COUNT(extras1) topping_count
FROM customer_orders2 co
INNER JOIN pizza_runner.pizza_toppings pt ON co.extras1::INT = pt.topping_id 
GROUP BY topping_name
ORDER BY topping_count DESC;
```

###### Python

```python
# copy a table
df = c_o

df['extras'] = df['extras'].astype(str)

# normalize a table
# split toppings column by comma, and stack them up
# rename column
# get rid of comma (regex=regular expressions)
# reset index
result_df = df.apply(lambda x: pd.Series(x['extras'].split(' ')), axis=1).stack().rename('extra').replace(',','', regex=True).reset_index(level=1, drop=True)

# count extra topping
result_df = result_df.to_frame().groupby('extra')['extra'].count().rename('extra_count')

# reset index
result_df = result_df.to_frame().reset_index()

# ignore null, change data type
result_df = result_df.apply(pd.to_numeric, errors='coerce')

# join tables
merged_df = result_df.merge(pizza_toppings, how='left', left_on='extra', right_on='topping_id')

# select relevant columns
# exclude null topping_name
merged_df[['topping_name', 'extra_count']][~(merged_df.topping_name.isna())]
```

| topping_name | topping_count |
|-----------|----------------|
| Bacon         | 4             |
| Chicken         | 1             |
| Cheese         | 1             |

###### Python Plot

```python
common_extra.plot(kind='bar', x='topping_name', y='extra_count', title='Top 3 Commonly Added Extras')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/bbbc5887-c4ec-476a-916b-5d174bf364cb" align="center" width="362" height="324" >

---

### 3. What was the most common exclusion?
###### SQL

```TSQL
SELECT topping_name, COUNT(exclusions1) exclusion_count
FROM customer_orders2 co
INNER JOIN pizza_runner.pizza_toppings pt ON co.exclusions1 = pt.topping_id 
GROUP BY topping_name
ORDER BY exclusion_count DESC;
```

###### Python

```python
# copy a table
df = c_o

df['exclusions'] = df['exclusions'].astype(str)

# normalize a table
# split toppings column by comma, and stack them up
# rename column
# get rid of comma (regex=regular expressions)
# reset index
result_df = df.apply(lambda x: pd.Series(x['exclusions'].split(' ')), axis=1).stack().rename('exclusion').replace(',','', regex=True).reset_index(level=1, drop=True)

# count extra topping
result_df = result_df.to_frame().groupby('exclusion')['exclusion'].count().rename('exclusion_count')

# reset index
result_df = result_df.to_frame().reset_index()

# ignore null, change data type
result_df = result_df.apply(pd.to_numeric, errors='coerce')

# join tables
merged_df = result_df.merge(pizza_toppings, how='left', left_on='exclusion', right_on='topping_id')

# select relevant columns
# exclude null topping_name
merged_df[['topping_name', 'exclusion_count']][~(merged_df.topping_name.isna())].sort_values('exclusion_count', ascending=False)
```

| topping_name | exclusion_count |
|-----------|----------------|
| Cheese         | 4             |
| Mushrooms         | 1             |
| BBQ Sauce         | 1             |

###### Python Plot

```python
common_exclusion.plot(kind='bar', x='topping_name', y='exclusion_count', title='Common Exclusions')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/2ff2c077-19a6-4243-a05a-818d14c3441b" align="center" width="372" height="327" >

---

### 4. Generate an order item for each record in the `customers_orders` table in the format of one of the following:
* `Meat Lovers`
* `Meat Lovers - Exclude Beef`
* `Meat Lovers - Extra Bacon`
* `Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers`

First, we are going to make a table to tackle this question. 

###### SQL

```TSQL
DROP TABLE IF EXISTS extras_exclusions;

--there are max 2 different values in the exclusions and extras (ex. '1, 5') we are gonna split into two seperate columns.
CREATE TABLE extras_exclusions AS 
  (SELECT order_id, customer_id, pizza_id, 
          split_part(exclusions, ',', 1) AS excl1,
          split_part(exclusions, ',', 2) AS excl2,
          split_part(extras, ',', 1) AS extr1,
          split_part(extras, ',', 2) AS extr2
   FROM customer_orders1
   ORDER BY order_id);

UPDATE extras_exclusions
SET excl1 = CASE WHEN excl1 IS NULL OR excl1 = '' OR excl1='null' THEN NULL
            ELSE excl1 END,
	excl2 = CASE WHEN excl2 IS NULL OR excl2 = '' OR excl2='null' THEN NULL
            ELSE excl2 END,
    extr1 = CASE WHEN extr1 IS NULL OR extr1 = '' OR extr1='null' THEN NULL
            ELSE extr1 END,
	extr2 = CASE WHEN extr2 IS NULL OR extr2 = '' OR extr2='null' THEN NULL
            ELSE extr2 END;

ALTER TABLE extras_exclusions
ALTER COLUMN excl1 TYPE INT
USING (TRIM(excl1)::INT),
ALTER COLUMN extr1 TYPE INT
USING (TRIM(extr1)::INT),
ALTER COLUMN excl2 TYPE INT
USING (TRIM(excl2)::INT),
ALTER COLUMN extr2 TYPE INT
USING (TRIM(extr2)::INT);
```

###### Python

```python
# copy customer_orders table
df = c_o

# make sure exclusions data type is string in order to split them
df['exclusions'] = df['exclusions'].astype(str)

# split exclusions column, delete comma, rename columns  
result_df = df.apply(lambda x: pd.Series(x['exclusions'].split(' ')), axis=1).replace(',','', regex=True).rename(columns={0:'exclusion1', 1:'exclusion2'})

# add 'order_id', 'customer_id', 'pizza_id' columns back to the table
concat_df = pd.concat([df[['order_id', 'customer_id', 'pizza_id']], result_df], axis=1)

# do the same steps with extras column
df['extras'] = df['extras'].astype(str)

result_df2 = df.apply(lambda x: pd.Series(x['extras'].split(' ')), axis=1).replace(',','', regex=True).rename(columns={0:'extra1', 1:'extra2'})

merged_df = pd.concat([concat_df, result_df2], axis=1)

# select relevant columns
result_df = merged_df[['order_id', 'customer_id', 'pizza_id', 'extra1', 'extra2', 'exclusion1', 'exclusion2']]

# ignore null value, change all number to numeric data type
result_df = merged_df.apply(pd.to_numeric, errors='coerce')

result_df
```

Now the table looks like this. (First 5 rows)

| order_id | customer_id | pizza_id | excl1 | excl2 | extr1 | extr2 |
|----------|-------------|----------|-------|-------|-------|-------|
| 1        | 101         | 1        |       |       |       |       |
| 2        | 101         | 1        |       |       |       |       |
| 3        | 102         | 1        |       |       |       |       |
| 3        | 102         | 2        |       |       |       |       |
| 4        | 103         | 1        | 4     |       |       |       |

###### SQL

```TSQL
WITH cte AS (SELECT order_id, ee.pizza_id, pizza_name, pt.topping_name as excl1, pt1.topping_name as excl2, pt2.topping_name as extr1, pt3.topping_name as extr2
             FROM extras_exclusions ee
             LEFT JOIN pizza_runner.pizza_toppings pt ON ee.excl1=pt.topping_id
             LEFT JOIN pizza_runner.pizza_toppings pt1 ON ee.excl2=pt1.topping_id
             LEFT JOIN pizza_runner.pizza_toppings pt2 ON ee.extr1=pt2.topping_id
             LEFT JOIN pizza_runner.pizza_toppings pt3 ON ee.extr2=pt3.topping_id
             LEFT JOIN pizza_runner.pizza_names pn ON ee.pizza_id=pn.pizza_id)
            

SELECT order_id, 
       CASE WHEN pizza_id=1 AND excl1 IS NULL AND extr1 IS NULL THEN concat(pizza_name, excl1, ' ', extr1)
            WHEN pizza_id=1 AND excl1 IS NOT NULL AND excl2 IS NULL AND extr1 IS NULL AND extr2 IS NULL THEN concat(pizza_name,' - Exclude', ' ', excl1)
            WHEN pizza_id=1 AND excl1 IS NOT NULL AND excl2 IS NOT NULL AND extr1 IS NOT NULL AND extr2 IS NULL THEN concat(pizza_name,' - Exclude', ' ', excl1, ', ', excl2, ' - Extra', ' ', extr1)
            WHEN pizza_id=1 AND excl1 IS NOT NULL AND excl2 IS NOT NULL AND extr1 IS NOT NULL AND extr2 IS NOT NULL THEN concat(pizza_name,' - Exclude', ' ', excl1, ', ', excl2, ' - Extra', ' ', extr1, ', ', extr2)
            WHEN pizza_id=1 AND excl1 IS NULL AND extr1 IS NOT NULL AND extr2 IS NULL THEN concat(pizza_name,' - Extra', ' ', extr1)
            WHEN pizza_id=1 AND excl1 IS NULL AND extr1 IS NOT NULL AND extr2 IS NOT NULL THEN concat(pizza_name,' - Extra', ' ', extr1)
            WHEN pizza_id=2 AND excl1 IS NULL AND extr1 IS NULL THEN concat(pizza_name, excl1, ' ', extr1)
            WHEN pizza_id=2 AND excl1 IS NOT NULL AND excl2 IS NULL AND extr1 IS NULL AND extr2 IS NULL THEN concat(pizza_name,' - Exclude', ' ', excl1)
            WHEN pizza_id=2 AND excl1 IS NOT NULL AND excl2 IS NOT NULL AND extr1 IS NOT NULL AND extr2 IS NULL THEN concat(pizza_name,' - Exclude', ' ', excl1, ', ', excl2, ' - Extra', ' ', extr1)
            WHEN pizza_id=2 AND excl1 IS NOT NULL AND excl2 IS NOT NULL AND extr1 IS NOT NULL AND extr2 IS NOT NULL THEN concat(pizza_name,' - Exclude', ' ', excl1, ', ', excl2, ' - Extra', ' ', extr1, ', ', extr2)    
            WHEN pizza_id=2 AND excl1 IS NULL AND extr1 IS NOT NULL AND extr2 IS NULL THEN concat(pizza_name,' - Extra', ' ', extr1)
            WHEN pizza_id=2 AND excl1 IS NULL AND extr1 IS NOT NULL AND extr2 IS NOT NULL THEN concat(pizza_name,' - Extra', ' ', extr1, ', ', extr2)
       ELSE pizza_name END AS pizza_details
FROM cte
ORDER BY order_id;
```

###### Python

```python
# merge result_df and pizza_names table
merge_df = result_df.merge(pizza_names, how='left', on='pizza_id')

# make sets of columns where I want to use to join with pizza_names table, and the new names for the columns
merge_columns = {
    'extra1': 'extra1_name',
    'extra2': 'extra2_name',
    'exclusion1': 'exclusion1_name',
    'exclusion2': 'exclusion2_name'
}

# use for loop to join 4 times
for column, name in merge_columns.items():
    merge_df = merge_df.merge(pizza_toppings, how='left', left_on=column, right_on='topping_id')
    merge_df = merge_df.rename(columns={"topping_name": name})

# choose necessary columns
unnested_df = merge_df[['order_id', 'customer_id', 'pizza_id', 'pizza_name', 'extra1_name', 'extra2_name', 'exclusion1_name', 'exclusion2_name']]

# Create the 'pizza_details' column using numpy.where()

unnested_df['pizza_details'] = np.where((unnested_df['pizza_id'] == 1) &
                                                 (unnested_df['exclusion1_name'].notna()) &
                                                 (unnested_df['exclusion2_name'].isna()) &
                                                 (unnested_df['extra1_name'].isna()) &
                                                 (unnested_df['extra2_name'].isna()),
                                                 unnested_df['pizza_name'] + ' - Exclude ' + unnested_df['exclusion1_name'].astype(str),
                                                 np.where((unnested_df['pizza_id'] == 1) &
                                                          (unnested_df['exclusion1_name'].notna()) &
                                                          (unnested_df['exclusion2_name'].notna()) &
                                                          (unnested_df['extra1_name'].notna()) &
                                                          (unnested_df['extra2_name'].isna()),
                                                          unnested_df['pizza_name'] + ' - Exclude ' + unnested_df['exclusion1_name'].astype(str) + ', ' + unnested_df['exclusion2_name'].astype(str) + ' - Extra '+ unnested_df['extra1_name'].astype(str),
                                                          np.where((unnested_df['pizza_id'] == 1) &
                                                                   (unnested_df['exclusion1_name'].notna()) &
                                                                   (unnested_df['exclusion2_name'].notna()) &
                                                                   (unnested_df['extra1_name'].notna()) &
                                                                   (unnested_df['extra2_name'].notna()),
                                                                   unnested_df['pizza_name'] + ' - Exclude ' + unnested_df['exclusion1_name'].astype(str) + ', ' + unnested_df['exclusion2_name'].astype(str) + ' - Extra '+ unnested_df['extra1_name'].astype(str) + ', ' + unnested_df['extra2_name'].astype(str),
                                                                   np.where((unnested_df['pizza_id'] == 1) &
                                                                            (unnested_df['exclusion1_name'].isna()) &
                                                                            (unnested_df['extra1_name'].notna()) &
                                                                            (unnested_df['extra2_name'].isna()),
                                                                            unnested_df['pizza_name'] + ' - Extra ' + unnested_df['extra1_name'].astype(str),
                                                                            np.where((unnested_df['pizza_id'] == 1) &
                                                                                     (unnested_df['exclusion1_name'].isna()) &
                                                                                     (unnested_df['extra1_name'].notna()) &
                                                                                     (unnested_df['extra2_name'].notna()),
                                                                                     unnested_df['pizza_name'] + ' - Extra ' + unnested_df['extra1_name'].astype(str)+ ', ' + unnested_df['extra2_name'].astype(str),
                                                                                             np.where((unnested_df['pizza_id'] == 2) &
                                                                                                       (unnested_df['exclusion1_name'].notna()) &
                                                                                                       (unnested_df['exclusion2_name'].isna()) &
                                                                                                       (unnested_df['extra1_name'].isna()) &
                                                                                                       (unnested_df['extra2_name'].isna()),
                                                                                                       unnested_df['pizza_name'] + ' - Exclude ' + unnested_df['exclusion1_name'].astype(str),
                                                                                                       np.where((unnested_df['pizza_id'] == 2) &
                                                                                                                (unnested_df['exclusion1_name'].notna()) &
                                                                                                                (unnested_df['exclusion2_name'].notna()) &
                                                                                                                (unnested_df['extra1_name'].notna()) &
                                                                                                                (unnested_df['extra2_name'].isna()),
                                                                                                                 unnested_df['pizza_name'] + ' - Exclude ' + unnested_df['exclusion1_name'].astype(str) + ', ' + unnested_df['exclusion2_name'].astype(str) + ' - Extra '+ unnested_df['extra1_name'].astype(str),
                                                                                                                 np.where((unnested_df['pizza_id'] == 2) &
                                                                                                                          (unnested_df['exclusion1_name'].notna()) &
                                                                                                                          (unnested_df['exclusion2_name'].notna()) &
                                                                                                                          (unnested_df['extra1_name'].notna()) &
                                                                                                                          (unnested_df['extra2_name'].notna()),
                                                                                                                           unnested_df['pizza_name'] + ' - Exclude ' + unnested_df['exclusion1_name'].astype(str) + ', ' + unnested_df['exclusion2_name'].astype(str) + ' - Extra '+ unnested_df['extra1_name'].astype(str) + ', ' + unnested_df['extra2_name'].astype(str),
                                                                                                                           np.where((unnested_df['pizza_id'] == 2) &
                                                                                                                                    (unnested_df['exclusion1_name'].isna()) &
                                                                                                                                    (unnested_df['extra1_name'].notna()) &
                                                                                                                                    (unnested_df['extra2_name'].isna()),
                                                                                                                                     unnested_df['pizza_name'] + ' - Extra ' + unnested_df['extra1_name'].astype(str),
                                                                                                                                     np.where((unnested_df['pizza_id'] == 2) &
                                                                                                                                              (unnested_df['exclusion1_name'].isna()) &
                                                                                                                                              (unnested_df['extra1_name'].notna()) &
                                                                                                                                              (unnested_df['extra2_name'].notna()),
                                                                                                                                               unnested_df['pizza_name'] + ' - Extra ' + unnested_df['extra1_name'].astype(str)+ ', ' + unnested_df['extra2_name'].astype(str),
                                        unnested_df['pizza_name']))))))))))


# choose relevant columns
unnested_df[['order_id', 'pizza_details']]
```

First 5 rows will look like this.

| order_id | pizza_details               |
|----------|-----------------------------|
| 1        | Meatlovers                  |
| 2        | Meatlovers                  |
| 3        | Vegetarian                  |
| 3        | Meatlovers                  |
| 4        | Vegetarian - Exclude Cheese |

---

### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the `customer_orders` table and add a 2x in front of any relevant ingredients

For example: `"Meat Lovers: 2xBacon, Beef, ... , Salami"`

###### SQL

```TSQL
--Add a row number column to the cleaned customer_orders1 table.
SELECT *, ROW_NUMBER() OVER(ORDER BY order_id, pizza_id) order_n
INTO customer_orders1_rn
FROM customer_orders1;
```

###### Python

```python
# copy table
rn_df = c_o

rn_df['order_id'] = rn_df['order_id'].astype(int)
rn_df['pizza_id'] = rn_df['pizza_id'].astype(int)

# row_number
rn_df['order_n'] = rn_df['order_time'].rank(method='first').astype(int)

rn_df
```

Build a table with basic recipe.

###### SQL

```TSQL
DROP TABLE IF EXISTS base_recipe;
CREATE TEMP TABLE base_recipe AS 
   
   SELECT
     t4.row_number,
     t4.order_id,
     t4.customer_id,
     t1.pizza_id,
     t1.pizza_name,
     t2.topping,
     t3.topping_name
   FROM
     pizza_runner.pizza_names t1
     JOIN pizza_recipes1 t2 ON t1.pizza_id=t2.pizza_id
     JOIN pizza_runner.pizza_toppings t3 ON t2.topping=t3.topping_id
     RIGHT JOIN customer_orders1_rn t4 ON t1.pizza_id=t4.pizza_id;
```

###### Python

```python
# copy table
df=pizza_recipes

# unnest pizza_recipes table
unnested_recipes = df.apply(lambda x: pd.Series(x['toppings'].split(' ')), axis=1).stack().replace(',','', regex=True).reset_index(level=1, drop=True).rename('topping')

# concat pizza_id and topping columns 
unnested_recipes = pd.concat([df['pizza_id'], unnested_recipes], axis=1)

# inner join pizza_names and unnested_recipes tables
merge_df = pizza_names.merge(unnested_recipes, how='inner')

# change data type for merge_df.topping to integer
merge_df['topping'] = merge_df['topping'].astype(int)

# inner join merge_df and pizza_toppings tables
merge_df = merge_df.merge(pizza_toppings, how='inner', left_on='topping', right_on='topping_id')

# right join merge_df and rn_df(c_o w/ row_number) tables
merge_df = merge_df.merge(rn_df, how='right')

# choose relelvant columns
base_recipes = merge_df[['order_n', 'order_id', 'customer_id', 'pizza_id', 'pizza_name', 'topping', 'topping_id']]

base_recipes
```

Make 2 seperate tables for exclusions and extras.

###### SQL

```TSQL
 -- Exclusions table
 DROP TABLE IF EXISTS order_exclusions;
 CREATE TEMP TABLE order_exclusions AS 
 SELECT
   row_number_order,
   order_id,
   customer_id,
   t1.pizza_id,
   pizza_name,
   CAST(UNNEST(string_to_array(COALESCE(exclusions, '0'), ','))AS INT) AS exclusions
 FROM
   customer_orders_cleaned t1
 JOIN pizza_runner.pizza_names t2 ON t1.pizza_id=t2.pizza_id
 ORDER BY
   order_id;
   
-- Extra table
DROP TABLE IF EXISTS order_extras;
 CREATE TEMP TABLE order_extras AS 
 SELECT
   row_number,
   order_id,
   customer_id,
   t1.pizza_id,
   pizza_name,
   CAST(UNNEST(string_to_array(COALESCE(extras, '0'), ','))AS INT) AS extras
 FROM
   customer_orders1_rn t1
 JOIN pizza_runner.pizza_names t2 ON t1.pizza_id=t2.pizza_id
 ORDER BY
   order_id;
```

###### Python

```python
#exclusion table
exc_unnest_df = c_o.apply(lambda x: pd.Series(x['exclusions'].split(' ')), axis=1).stack().replace(',','', regex=True).reset_index(level=1, drop=True).rename('exclusion')

exc_unnest_df = pd.concat([rn_df[['order_n', 'order_id', 'customer_id', 'pizza_id']], exc_unnest_df], axis=1)

exc_unnest_df = exc_unnest_df.merge(pizza_names, how='left')

# handle null value
exc_unnest_df['exclusion'] = exc_unnest_df['exclusion'].replace('', np.nan)
exc_unnest_df['exclusion'] = pd.to_numeric(exc_unnest_df['exclusion'], errors='coerce', downcast='integer')
exc_unnest_df['exclusion'] = exc_unnest_df['exclusion'].fillna(0).astype(int)

exc_unnest_df

---

# extra table
ext_unnest_df = c_o.apply(lambda x: pd.Series(x['extras'].split(' ')), axis=1).stack().replace(',','', regex=True).reset_index(level=1, drop=True).rename('extra')

ext_unnest_df = pd.concat([rn_df[['order_n', 'order_id', 'customer_id', 'pizza_id']], ext_unnest_df], axis=1)

ext_unnest_df = ext_unnest_df.merge(pizza_names, how='left')

# handle null value
ext_unnest_df['extra'] = ext_unnest_df['extra'].replace('', np.nan)
ext_unnest_df['extra'] = pd.to_numeric(ext_unnest_df['extra'], errors='coerce', downcast='integer')
ext_unnest_df['extra'] = ext_unnest_df['extra'].fillna(0).astype(int)

ext_unnest_df
```

Join all the tables (Union extras, Except exclusions)

###### SQL

```TSQL
DROP TABLE IF EXISTS pizzas_details;
    CREATE TEMP TABLE pizzas_details AS
    WITH first_layer AS (SELECT
      row_number,
      order_id,
      customer_id,
      pizza_id,
      pizza_name,
      topping
    FROM
      base_recipe
    EXCEPT
    SELECT
      *
    FROM
      order_exclusions
    UNION ALL
    SELECT
      *
    FROM
      order_extras
    WHERE
      extras != 0)
    SELECT
      row_number,
      order_id,
      customer_id,  
      pizza_id,
      pizza_name,
      first_layer.topping,
      topping_name
    FROM
      first_layer
    LEFT JOIN pizza_runner.pizza_toppings ON first_layer.topping = pizza_toppings.topping_id
    ORDER BY
      row_number,
      order_id,
      pizza_id,
      topping_id;
```

###### Python

```python
# merge base_recipes and exc_unnest_df, indicator can tell kind of merge on table
result_df = base_recipes[['order_n', 'order_id', 'customer_id', 'pizza_id', 'pizza_name', 'topping']] \
    .merge(exc_unnest_df, how='left', left_on=['order_n', 'topping'], right_on=['order_n', 'exclusion'], indicator=True)

# filter to keep only left table values
result_df = result_df[result_df['_merge']=='left_only']

result_df = result_df[['order_n', 'order_id_x', 'customer_id_x', 'pizza_id_x', 'pizza_name_x', 'topping']]

result_df = result_df.rename(columns={'order_id_x':'order_id', 'customer_id_x': 'customer_id', 'pizza_id_x': 'pizza_id', 'pizza_name_x': 'pizza_name'})

ext_unnest_df = ext_unnest_df[ext_unnest_df['extra']!=0]

ext_unnest_df

result_df = pd.concat([result_df, ext_unnest_df])

result_df = result_df.merge(pizza_toppings, how='left', left_on='topping', right_on='topping_id')
result_df = result_df.merge(pizza_toppings, how='left', left_on='extra', right_on='topping_id')

# topping_name_x IS NULL means there's extra topping so bring topping_name_y over topping_name_x
result_df['topping_name_x'] = np.where(result_df['topping_name_x'].isna(), result_df['topping_name_y'], result_df['topping_name_x'])

# select relevant column, and rename a column to topping_name
result_df = result_df[['order_n', 'order_id', 'customer_id', 'pizza_id', 'pizza_name', 'topping', 'topping_name_x']].rename(columns={'topping_name_x': 'topping_name'})

result_df
```

Reshape the table to answer the question.

###### SQL

```TSQL
WITH counting_table AS(
   SELECT
     row_number,
     order_id,
     customer_id,
     pizza_id,
     pizza_name,
     topping,
     topping_name,
     COUNT(topping) AS count_ingredient
   FROM
     pizzas_details
   GROUP BY
     row_number,
     order_id,
     customer_id,
     pizza_id,
     pizza_name,
     topping,
     topping_name)
   , text_table AS(
   SELECT
     row_number,
     order_id,
     pizza_id,
     pizza_name,
     topping,
     CASE WHEN count_ingredient = 1 THEN topping_name
          ELSE CONCAT(count_ingredient, 'x ', topping_name)
     END AS ingredient_count
   FROM counting_table)
   , group_text AS(
   SELECT
     row_number,
     order_id,
     pizza_id,
     pizza_name,
     STRING_AGG(ingredient_count, ', ') AS recipe
   FROM
     text_table
   GROUP BY
     row_number,
     order_id,
     pizza_id,
     pizza_name)
   SELECT
     order_id,
     CONCAT(pizza_name, ': ', recipe) recipe
   FROM
     group_text
   ORDER BY
     row_number,
     order_id;
```

###### Python

```python
# create a table to count extra topping
counting_df = result_df

# counting_df['ingredient_n'] = counting_df.groupby(['order_n', 'order_id', 'customer_id', 'pizza_id', 'pizza_name', 'topping_name'])['topping_name'].count()

counting_df = counting_df.groupby(['order_n', 'order_id', 'customer_id', 'pizza_id', 'pizza_name', 'topping_name'])['topping_name'].count()

# when I use groupby() it will make columns index so reset_index here
counting_df = pd.DataFrame(counting_df).rename(columns={'topping_name':'topping_n'}).reset_index()

# create a table to prepare text for extra toppings
text_df = counting_df

# you can't add str column and int column because of the data type difference, change 'topping_n' to str
text_df['ingredient_n'] = np.where(text_df['topping_n']==1, text_df['topping_name'], text_df['topping_n'].astype(str) + 'x ' + text_df['topping_name'])

# create a table to group columns
grouped_df = text_df.groupby(['order_n', 'order_id', 'customer_id', 'pizza_id', 'pizza_name'])

# concat all the ingredients and seperate by commas
grouped_lists = grouped_df['ingredient_n'].agg(lambda column: ", ".join(column))

grouped_lists = grouped_lists.reset_index(name="recipe")

grouped_lists['recipe'] = grouped_lists['pizza_name'] + ': ' + grouped_lists['recipe']

grouped_lists[['order_id', 'recipe']]
```

First 4 lines.

| order_id | recipe                                                                            |
|----------|-----------------------------------------------------------------------------------|
| 1        | Meatlovers: Cheese, Chicken, Salami, Bacon, Beef, Pepperoni, Mushrooms, BBQ Sauce |
| 2        | Meatlovers: Chicken, BBQ Sauce, Pepperoni, Salami, Cheese, Beef, Bacon, Mushrooms |
| 3        | Meatlovers: Salami, Chicken, BBQ Sauce, Beef, Bacon, Mushrooms, Pepperoni, Cheese |
| 3        | Vegetarian: Onions, Tomato Sauce, Mushrooms, Tomatoes, Peppers, Cheese            |

---

### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
###### SQL

```TSQL
SELECT topping_name, COUNT(topping) AS time_used
FROM pizzas_details
GROUP BY topping, topping_name
ORDER BY time_used DESC;
```

###### Python

```python
topping_rank =  result_df.groupby('topping_name')['topping_name'].count().sort_values(ascending=False)

topping_rank
```

First 5 lines.

| topping_name | time_used |
|--------------|-----------|
| Bacon        | 14        |
| Mushrooms    | 13        |
| Chicken      | 11        |
| Cheese       | 11        |
| Pepperoni    | 10        |

###### Python Plot

```python
topping_rank.plot(kind='bar', title='Total Quantity of Each Ingredient Used in All Delivered Pizzas')
```

<img src="https://github.com/KannaKit/8_week_SQL_challenge_with_python/assets/106714718/f5dee214-b8c2-4f28-b02e-500fac1aea51" align="center" width="385" height="339" >
