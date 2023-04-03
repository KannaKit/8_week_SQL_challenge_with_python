--------------------------------
--CASE STUDY #2: PIZZA RUNNER--
--------------------------------
--Author: Kanna Schellenger
--Date: 04/01/2023
--Tool used: PostgreSQL


-- Copying table to new table
DROP TABLE IF EXISTS customer_orders1;
CREATE TABLE customer_orders1 AS
(SELECT * FROM customer_orders);

-- Cleaning data
UPDATE customer_orders1
SET exclusions = CASE exclusions WHEN 'null' THEN null
                                 WHEN '' THEN null 
                 ELSE exclusions END,
    extras = CASE extras WHEN 'null' THEN null 
                         WHEN '' THEN null 
             ELSE extras END;
 
 -- Copying table and cleaning data
DROP TABLE IF EXISTS runner_orders1;
CREATE TABLE runner_orders1 AS
(SELECT order_id, runner_id, pickup_time, 
        CASE WHEN distance LIKE '%km' THEN TRIM('km' FROM distance)
        ELSE distance END AS distance,
        CASE WHEN duration LIKE '%minutes' THEN TRIM('minutes' FROM duration)
             WHEN duration LIKE '%mins' THEN TRIM('mins' FROM duration)
             WHEN duration LIKE '%minute' THEN TRIM('minute' FROM duration)
        ELSE duration END AS duration, cancellation
FROM runner_orders);

-- Cleaning data
UPDATE runner_orders1
SET pickup_time = CASE WHEN pickup_time = 'null' THEN null ELSE pickup_time END,
    distance = CASE distance WHEN 'null' THEN null ELSE distance END,
    duration = CASE duration WHEN 'null' THEN null ELSE duration END,
    cancellation= CASE cancellation WHEN 'null' THEN null 
                                    WHEN '' THEN null 
                  ELSE cancellation END;
    

ALTER TABLE runner_orders1
ALTER COLUMN pickup_time TYPE TIMESTAMP
USING to_timestamp(pickup_time, 'YYYY-MM-DD HH24:MI:SS'),
ALTER COLUMN distance TYPE float(1)
USING nullif(distance, '')::float(1),
ALTER COLUMN duration TYPE INT
USING nullif(duration, '')::INT;

ALTER TABLE runners
ALTER COLUMN registration_date TYPE date;
