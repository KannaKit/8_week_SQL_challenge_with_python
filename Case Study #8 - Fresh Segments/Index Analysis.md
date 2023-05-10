# 🍊 Case Study #8 - Fresh Segments
## 📒 Index Analysis

The `index_value` is a measure which can be used to reverse calculate the average `composition` for Fresh Segments’ clients.

Average composition can be calculated by dividing the composition column by the `index_value` column rounded to 2 decimal places.

### 1. What is the top 10 interests by the average composition for each month?

```TSQL
WITH cte AS (
SELECT 
  month_year,
  interest_id,
  ROUND(CAST(composition/index_value AS NUMERIC),2) avg_composition,
  RANK() OVER(PARTITION BY month_year ORDER BY ROUND(CAST(composition/index_value AS NUMERIC),2) DESC) rank_n
FROM interest_metrics
WHERE month_year IS NOT NULL
ORDER BY month_year, avg_composition DESC
)

SELECT
  month_year,
  interest_id,
  interest_name,
  interest_summary,
  avg_composition
FROM cte
LEFT JOIN interest_map map ON cte.interest_id=map.id
WHERE rank_n <= 10
ORDER BY month_year, rank_n;
```

First 5 rows.

| month_year | interest_id | interest_name                 | interest_summary                                                                                                                                          | avg_composition |
|------------|-------------|-------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------|
| 2018-07-01 | 	6324	        | Las Vegas Trip Planners       | People researching attractions and accommodations in Las Vegas. These consumers are more likely to spend money on flights, hotels, and local attractions. | 	7.36            |
| 2018-07-01 | 	6284	        | Gym Equipment Owners          | People researching and comparing fitness trends and techniques. These consumers are more likely to spend money on gym equipment for their homes.          | 	6.94            |
| 2018-07-01 | 	4898	        | Cosmetics and Beauty Shoppers | Consumers comparing and shopping for cosmetics and beauty products.                                                                                       | 	6.78            |
| 2018-07-01 | 	77	          | Luxury Retail Shoppers        | Consumers shopping for high end fashion apparel and accessories.                                                                                          | 	6.61            |
| 2018-07-01 | 	39	          | Furniture Shoppers            | Consumers shopping for major home furnishings.                                                                                                            | 	6.51            |

---

### 2. For all of these top 10 interests - which interest appears the most often?

```TSQL
WITH cte AS (
SELECT 
  month_year,
  interest_id,
  ROUND(CAST(composition/index_value AS NUMERIC),2) avg_composition,
  RANK() OVER(PARTITION BY month_year ORDER BY ROUND(CAST(composition/index_value AS NUMERIC),2) DESC) rank_n
FROM interest_metrics
WHERE month_year IS NOT NULL
ORDER BY month_year, avg_composition DESC),

cte2 AS (
SELECT
  month_year,
  interest_id,
  interest_name,
  interest_summary,
  avg_composition
FROM cte
LEFT JOIN interest_map map ON cte.interest_id=map.id
WHERE rank_n <= 10
ORDER BY month_year, rank_n),

cte3 AS (
SELECT 
  COUNT(interest_id) interest_id_count,
  interest_name, 
  interest_summary
FROM cte2
GROUP BY interest_id, interest_name, interest_summary
ORDER BY interest_id_count DESC)

SELECT
  interest_id_count,
  interest_name,
  interest_summary
FROM cte3
WHERE interest_id_count=10
GROUP BY interest_id_count, interest_name, interest_summary;
```

| interest_id_count | interest_name            | interest_summary                                                                                                                                        |
|-------------------|--------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| 10	                | Alabama Trip Planners    | People researching attractions and accommodations in Alabama. These consumers are more likely to spend money on flights, hotels, and local attractions. |
| 10	                | Luxury Bedding Shoppers  | Consumers shopping for luxury bedding.                                                                                                                  |
| 10	                | Solar Energy Researchers | Consumers researching products and services to use solar energy.                                                                                        |

---

### 3. What is the average of the average composition for the top 10 interests for each month?

```TSQL
WITH cte AS (
SELECT 
  month_year,
  interest_id,
  ROUND(CAST(composition/index_value AS NUMERIC),2) avg_composition,
  RANK() OVER(PARTITION BY month_year ORDER BY ROUND(CAST(composition/index_value AS NUMERIC),2) DESC) rank_n
FROM interest_metrics
WHERE month_year IS NOT NULL
ORDER BY month_year, avg_composition DESC),

cte2 AS (
SELECT
  month_year,
  interest_id,
  interest_name,
  interest_summary,
  avg_composition
FROM cte
LEFT JOIN interest_map map ON cte.interest_id=map.id
WHERE rank_n <= 10
ORDER BY month_year, rank_n)

SELECT 
  month_year,
  ROUND(AVG(avg_composition),2) avg_avg_composition
FROM cte2
GROUP BY month_year
ORDER BY 1;
```

| month_year | avg_avg_composition |
|------------|---------------------|
| 2018-07-01 | 	6.04                |
| 2018-08-01 | 	5.95                |
| 2018-09-01 | 	6.90                |
| 2018-10-01 | 	7.07                |
| 2018-11-01 | 	6.62                |

---

### 4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.

```TSQL
WITH cte AS (
SELECT 
  month_year,
  interest_id,
  ROUND(CAST(composition/index_value AS NUMERIC),2) avg_composition,
  MAX(ROUND(CAST(composition/index_value AS NUMERIC),2)) OVER(PARTITION BY month_year) max_avg_composition
FROM interest_metrics
WHERE month_year IS NOT NULL),

cte2 AS (
SELECT *
FROM cte
WHERE avg_composition=max_avg_composition),

cte3 AS (
SELECT
  month_year,
  interest_name,
  max_avg_composition max_index_composition,
  ROUND(AVG(max_avg_composition) OVER(ORDER BY month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS three_month_moving_avg
FROM cte2
LEFT JOIN interest_map map ON cte2.interest_id=map.id),

cte4 as 
(SELECT 
  *,
  LAG(interest_name) OVER(ORDER BY month_year) || ': ' || LAG(max_index_composition) OVER(ORDER BY month_year) one_month_ago,
  LAG(interest_name, 2) OVER(ORDER BY month_year) || ': ' || LAG(max_index_composition,2) OVER(ORDER BY month_year) three_month_ago
FROM cte3)

SELECT *
FROM cte4
WHERE month_year > '2018-08-01';
```

| month_year | interest_name              | max_index_composition | three_month_moving_avg | one_month_ago                    | three_month_ago                  |
|------------|----------------------------|-----------------------|------------------------|----------------------------------|----------------------------------|
| 2018-09-01 | Work Comes First Travelers | 	8.26                  | 7.61	                   | Las Vegas Trip Planners: 7.21    | Las Vegas Trip Planners: 7.36    |
| 2018-10-01 | Work Comes First Travelers | 	9.14                  | 8.20	                   | Work Comes First Travelers: 8.26 | Las Vegas Trip Planners: 7.21    |
| 2018-11-01 | Work Comes First Travelers | 	8.28                  | 8.56	                   | Work Comes First Travelers: 9.14 | Work Comes First Travelers: 8.26 |
| 2018-12-01 | Work Comes First Travelers | 	8.31                  | 8.58	                   | Work Comes First Travelers: 8.28 | Work Comes First Travelers: 9.14 |
| 2019-01-01 | Work Comes First Travelers | 	7.66                  | 8.08	                   | Work Comes First Travelers: 8.31 | Work Comes First Travelers: 8.28 |

