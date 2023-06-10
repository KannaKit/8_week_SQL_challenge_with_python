# 🍕 Case Study #2 - Pizza Runner
## 💰 D. Pricing and Ratings
### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
###### SQL

```TSQL
SELECT SUM(CASE WHEN pizza_id = 1 THEN 12
                WHEN pizza_id = 2 THEN 10
           ELSE pizza_id END) AS total_sales
FROM customer_orders1_rn t1
JOIN runner_orders1 t2 ON t1.order_id=t2.order_id
WHERE cancellation IS NULL;
```

###### Python

```python
price = r_c_n_s

price['pr'] = np.where(price['pizza_name']=='Meatlovers', 12, 10)

sum(price.pr)
```

| total_sales | 
|----------|
| 138        | 

---

### 2. What if there was an additional $1 charge for any pizza extras?
###### SQL

```TSQL
SELECT SUM(CASE WHEN pizza_id = 1 THEN 12
                WHEN pizza_id = 2 THEN 10
           ELSE 0 END) +
       SUM(CASE WHEN extr1 IS NOT NULL AND extr2 IS NULL THEN 1
                WHEN extr2 IS NOT NULL AND extr2 IS NOT NULL THEN 2
           ELSE 0 END)AS total_sales
FROM extras_exclusions t1
JOIN runner_orders1 t2 ON t1.order_id=t2.order_id
WHERE cancellation IS NULL;
```

###### Python

```python
length_c_o = c_o

# check the length of extras column
length_c_o['length'] = length_c_o.extras.str.len()

# if length is 1 then $1 additional cost, if it's 4 then +$2, everything else is $0
length_c_o['extra_charge'] = np.where(length_c_o['length']==1, 1,
                             np.where(length_c_o['length']==4, 2, 0))

# filter out cancelled orders
price2 = length_c_o.merge(r_o, how='right')
price2 = price2[price2['cancellation'].isna()]

# add base pizza price column
price2['pr'] = np.where(price2['pizza_id']==1, 12, 10)

# add total column
price2['total'] = price2.pr + price2.extra_charge

# sum up all total column
price2.total.sum()
```

| total_sales | 
|----------|
| 142        | 

---

### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
###### SQL

```TSQL
DROP TABLE IF EXISTS ratings;
CREATE TABLE ratings  (
  "order_id" INTEGER,
  "rating" INTEGER CONSTRAINT check1to5_raating CHECK (
     "rating" between 1 and 5),
  "comment" VARCHAR(150)
);

INSERT INTO ratings 
  ("order_id", "rating", "comment")
VALUES
  (1, 5, 'Good service'),
  (2, 4, 'Good'),
  (3, 5, ''),
  (4, 3, 'Pizza arrived cold'),
  (5, 2, 'Rude delivery person'),
  (6, 5, ''),
  (7, NULL, ''),
  (8, NULL, ''),
  (9, 5, ''),
  (10, 5, 'Delicious pizza');
```

###### Python

```python
ratings = {
    'order_id':[1,2,3,4,5,6,7,8,9,10],
    'rating'  :[5,4,5,3,2,5,np.nan,np.nan,5,5],
    'comment' :['Good service','Good','', 'Pizza arrived cold','Rude delivery person', '', '', '', '', 'Delicious pizza']
          }

ratings = pd.DataFrame(ratings)

ratings
```

I created input system for the customers as well.

```python
# ask to input rating in integer, smallest 1, largest 5
rating = input("Please rate your experience on a sclae of 1 to 5: ")

comment = input("Please leave a comment! (optional)")

if rating.isdigit():
    rating = int(rating)
    if 1 <= rating <= 5:
        print("Thank you for your rating!")
    else:
        print("Invalid rating. Please enter a number between 1 and 5")
else:
    print("Invalid input. Please enter a number.")
```

First 4 rows.

| order_id | rating | comment            |
|----------|--------|--------------------|
| 1        | 5      | Good service       |
| 2        | 4      | Good               |
| 3        | 5      |                    |
| 4        | 3      | Pizza arrived cold |

---

### 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
* `customer_id`
* `order_id`
* `runner_id`
* `rating`
* `order_time`
* `pickup_time`
* Time between order and pickup
* Delivery duration
* Average speed
* Total number of pizzas

First, we are going to make a table to tackle this question. 

###### SQL

```TSQL
DROP TABLE IF EXISTS new_tb;
CREATE TABLE new_tb AS

(SELECT 
  t1.customer_id,
  t1.order_id,
  t2.runner_id,
  t3.rating,
  order_time,
  pickup_time,
  (pickup_time-order_time) as time_between_order_and_pickup,
  duration,
  ROUND(CAST(AVG(distance/duration*60)as numeric),1) as avg_speed,
  COUNT(t1.pizza_id) as total_n_of_pizzas
FROM customer_orders1 t1
JOIN runner_orders1 t2 ON t1.order_id=t2.order_id
JOIN ratings t3 ON t1.order_id=t3.order_id
WHERE cancellation IS NULL
GROUP BY t1.order_id, t1.customer_id, t2.runner_id, t3.rating, t1.order_time, t2.pickup_time, t2.duration
ORDER BY order_id);
```

###### Python

```python
# inner join runner_orders, customer_orders and ratings tables
df = r_o.merge(c_o, how='inner', on='order_id')
df = df.merge(ratings, how='inner', on='order_id')

# filter out cancelled orders
df = df[df['cancellation'].isna()]

# add time_between_order_and_pickup column
df['time_between_order_and_pickup'] = (df.pickup_time-df.order_time).dt.total_seconds()/60
df['time_between_order_and_pickup'] = df['time_between_order_and_pickup'].round(2)

# create a df to calculate each order's pizza count
pizza_count = c_o.groupby('order_id')['pizza_id'].count().reset_index(name='pizza_count')

# inner join pizza_count table
df = df.merge(pizza_count, how='inner', on='order_id')

# create a df to calculate each order's average speed
speed = df.groupby('order_id').apply(lambda x: (x['distance'] / x['duration']).astype(float) * 60).reset_index(name='avg_speed')

# merge tables
df = df.merge(speed, how='inner', on='order_id')

# group by order_id, choose all the relevant columns and choose first value
df = df.groupby('order_id')[['customer_id', 'runner_id', 'rating', 'order_time', 'pickup_time', 'time_between_order_and_pickup', 'duration', 'avg_speed', 'pizza_count']].first()

df
```

First row.

| customer_id | order_id | runner_id | rating | order_time          | pickup_time         | time_between_order_and_pickup | duration | avg_speed | total_n_of_pizzas |
|-------------|----------|-----------|--------|---------------------|---------------------|-------------------------------|----------|-----------|-------------------|
| 101         | 1        | 1         | 5      | 2020-01-01 18:05:02 | 2020-01-01 18:15:34 | 00:10:32                      | 32       | 37.5      | 1                 |

---

### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
###### SQL

```TSQL
WITH cte AS 
 (SELECT SUM(CASE WHEN pizza_id = 1 THEN 12
                  WHEN pizza_id = 2 THEN 10
             ELSE 0 END) as pizza_price
  FROM customer_orders1 t1 
  LEFT JOIN runner_orders1 t2 ON t1.order_id=t2.order_id
  WHERE cancellation IS NULL)
     ,runner_p AS
 (SELECT SUM(ROUND(CAST((distance*0.3) AS NUMERIC),2)) as runner_pay
  FROM runner_orders1
  WHERE cancellation IS NULL)

SELECT t1.pizza_price-t2.runner_pay as revenues_after_delivery
FROM cte t1, runner_p t2;
```

###### Python

```python
# r_o, c_o, pizza_names, only successful orders
price = r_c_n_s

# create pizza price column
price['pr'] = np.where(price['pizza_name']=='Meatlovers', 12, 10)


# price['runner_pay'] = price.distance*0.30

# price['profit']=price.pr-price.runner_pay

# sum total of pizza price 
total_pizza_profit = sum(price.pr)

# copy runner_orders table
runner_salary = r_o

# create runner_pay column, fill na with zero
runner_salary['runner_pay'] = (runner_salary.distance*0.30).fillna(0)

# calculate profit by total of pizza price - runner_pay
profit = sum(price.pr) - sum(runner_salary.runner_pay)

profit
```


| revenues_after_delivery | 
|----------|
| 94.44        | 
