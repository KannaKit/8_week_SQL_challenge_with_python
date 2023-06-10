# 🍕 Case Study #2 - Pizza Runner
## 👽 E. Bonus Questions
### If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

First, we will moderate `pizza_names` table.

###### SQL

```TSQL
DROP TABLE IF EXISTS pizza_names_added;
CREATE TEMP TABLE pizza_names_added AS (
  SELECT * FROM pizza_runner.pizza_names);
INSERT INTO pizza_names_added
VALUES
 (3, 'Supreme');
 ```
 
###### Python

```python
pizza_names_new = pizza_names

# add a new row using loc
pizza_names_new.loc['2']=[3, 'Supreme']

pizza_names_new
```
 
| pizza_id | pizza_name |
|----------|------------|
| 1        | Meatlovers |
| 2        | Vegetarian |
| 3        | Supreme    |
 
Next and lastly, we will add a new recipe to `pizza_recipes` table.

###### SQL

```TSQL
DROP TABLE IF EXISTS pizza_recipes_added;
CREATE TEMP TABLE pizza_recipes_added AS (
  SELECT * FROM pizza_runner.pizza_recipes);
INSERT INTO pizza_recipes_added
VALUES
 (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');
```

###### Python

```python
new_recipes = pizza_recipes

# add a new row with a new recipe
new_recipes.loc['2']=[3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12']

new_recipes
```

| pizza_id | toppings                              |
|----------|---------------------------------------|
| 1	        | 1, 2, 3, 4, 5, 6, 8, 10               |
| 2	        | 4, 6, 7, 9, 11, 12                    |
| 3	        | 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 |
