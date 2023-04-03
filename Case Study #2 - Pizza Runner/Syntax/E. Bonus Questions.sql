--------------------------------
--CASE STUDY #2: PIZZA RUNNER--
--------------------------------
--Author: Kanna Schellenger
--Date: 04/03/2023
--Tool used: PostgreSQL

--E. Bonus Questions
--If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

DROP TABLE IF EXISTS pizza_names_added;
CREATE TEMP TABLE pizza_names_added AS (
  SELECT * FROM pizza_runner.pizza_names);
INSERT INTO pizza_names_added
VALUES
 (3, 'Supreme');
 
 SELECT *
 FROM pizza_names_added;
 
 DROP TABLE IF EXISTS pizza_recipes_added;
CREATE TEMP TABLE pizza_recipes_added AS (
  SELECT * FROM pizza_runner.pizza_recipes);
INSERT INTO pizza_recipes_added
VALUES
 (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');
 
 SELECT *
 FROM pizza_recipes_added;