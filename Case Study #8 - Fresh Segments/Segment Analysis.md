# 🍊 Case Study #8 - Fresh Segments
## 👩‍💻 Segment Analysis
### 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any `month_year`? Only use the maximum composition value for each interest but you must keep the corresponding `month_year`
###### SQL

```TSQL
--top 10 interests
WITH cte AS (
SELECT
  month_year,
  interest_id,
  MAX(composition) OVER(PARTITION BY interest_id) AS max_composition
FROM interest_met_temp
WHERE month_year IS NOT NULL),

cte2 AS (
SELECT 
  *,
  DENSE_RANK() OVER(ORDER BY max_composition DESC) rank
FROM cte)

SELECT
  DISTINCT interest_id,
  interest_name,
  rank
FROM cte2
LEFT JOIN interest_map map ON cte2.interest_id=map.id
WHERE rank < 11
ORDER BY 3;
```

###### Python

```python
max_compo_df = removed_df[~removed_df['month_year'].isna()].groupby('interest_id')['composition'].max().reset_index(name='max_composition')
max_compo_df = max_compo_df.sort_values('max_composition', ascending=False).head(10)

merged_df = max_compo_df.merge(removed_df[['interest_id', 'month_year', 'composition']], how='left', left_on=['interest_id', 'max_composition'], right_on=['interest_id', 'composition'])
merged_df = merged_df[['month_year', 'interest_id', 'composition']].merge(i_map, how='left', left_on='interest_id', right_on='id')

merged_df[['month_year', 'interest_id', 'interest_name', 'interest_summary', 'composition']]
```

First 5 rows. 

| interest_id | interest_name                     | rank |
|-------------|-----------------------------------|------|
| 21057	       | Work Comes First Travelers        | 	1    |
| 6284	        | Gym Equipment Owners              | 	2    |
| 39	          | Furniture Shoppers                | 	3    |
| 77	          | Luxury Retail Shoppers            | 	4    |
| 12133	       | Luxury Boutique Hotel Researchers | 	5    |

###### SQL

```TSQL
--bottom 10 interests
WITH cte AS (
SELECT
  month_year,
  interest_id,
  MAX(composition) OVER(PARTITION BY interest_id) AS max_composition
FROM interest_met_temp
WHERE month_year IS NOT NULL),

cte2 AS (
SELECT 
  *,
  DENSE_RANK() OVER(ORDER BY max_composition DESC) rank
FROM cte)

SELECT
  DISTINCT interest_id,
  interest_name,
  rank
FROM cte2
LEFT JOIN interest_map map ON cte2.interest_id=map.id
ORDER BY 3 DESC
LIMIT 10;
```

###### Python

```python
min_compo_df = removed_df[~removed_df['month_year'].isna()].groupby('interest_id')['composition'].max().reset_index(name='max_composition')
min_compo_df = min_compo_df.sort_values('max_composition', ascending=False).tail(10)

merged_df = min_compo_df.merge(removed_df[['interest_id', 'month_year', 'composition']], how='left', left_on=['interest_id', 'max_composition'], right_on=['interest_id', 'composition'])
merged_df = merged_df[['month_year', 'interest_id', 'composition']].merge(i_map, how='left', left_on='interest_id', right_on='id')

merged_df[['month_year', 'interest_id', 'interest_name', 'interest_summary', 'composition']]
```

First 5 rows. 

| interest_id | interest_name                | rank |
|-------------|------------------------------|------|
| 33958	       | Astrology Enthusiasts        | 	555  |
| 37412	       | Medieval History Enthusiasts | 	554  |
| 19599	       | Dodge Vehicle Shoppers       | 	553  |
| 19635	       | Xbox Enthusiasts             | 	552  |
| 19591	       | Camaro Enthusiasts           | 	551  |

---

### 2. Which 5 interests had the lowest average `ranking` value?
###### SQL

```TSQL
SELECT 
  DISTINCT interest_id,
  interest_name,
  ROUND(AVG(ranking),1) avg_rank
FROM interest_met_temp imt
LEFT JOIN interest_map map ON imt.interest_id=map.id
GROUP BY interest_id, interest_name
ORDER BY avg_rank DESC
LIMIT 5;
```

###### Python

```python
avg_rank_df = removed_df.groupby('interest_id')['ranking'].mean().reset_index(name='avg_rank')

avg_rank_df = avg_rank_df.sort_values('avg_rank', ascending=False).head(5)

avg_rank_df = avg_rank_df.merge(i_map, how='left', left_on='interest_id', right_on='id')

avg_rank_df
```

| interest_id | interest_name                                      | avg_rank |
|-------------|----------------------------------------------------|----------|
| 42011	       | League of Legends Video Game Fans                  | 	1037.3   |
| 36343	       | Computer Processor and Data Center Decision Makers | 	974.1    |
| 33958	       | Astrology Enthusiasts                              | 	968.5    |
| 37412	       | Medieval History Enthusiasts                       | 	961.7    |
| 37421	       | Budget Mobile Phone Researchers                    | 	961.0    |

---

### 3. Which 5 interests had the largest standard deviation in their `percentile_ranking` value?
###### SQL

```TSQL
SELECT 
  DISTINCT interest_id,
  interest_name,
  ROUND(CAST(STDDEV(percentile_ranking) OVER(PARTITION BY interest_id)AS NUMERIC),2) std_percentile_ranking
FROM interest_met_temp imt
JOIN interest_map map
ON imt.interest_id = map.id
ORDER BY std_percentile_ranking DESC
LIMIT 5;
```

###### Python

```python
std_df = removed_df.groupby('interest_id')['percentile_ranking'].std().reset_index(name='std_pct_rnk')
std_df = std_df.sort_values('std_pct_rnk', ascending=False).head(5)

std_df = std_df.merge(i_map, how='left', left_on='interest_id', right_on='id')

std_df
```

| interest_id | interest_name                          | std_percentile_ranking |
|-------------|----------------------------------------|------------------------|
| 23	          | Techies                                | 	30.18                  |
| 20764	       | Entertainment Industry Decision Makers | 	28.97                  |
| 38992	       | Oregon Trip Planners                   | 	28.32                  |
| 43546	       | Personalized Gift Shoppers             | 	26.24                  |
| 10839	       | Tampa and St Petersburg Trip Planners  | 	25.61                  |

---

### 4. For the 5 interests found in the previous question - what was minimum and maximum `percentile_ranking` values for each interest and its corresponding `year_month` value? Can you describe what is happening for these 5 interests?
###### SQL

```TSQL
--Minimum
WITH cte AS (
  SELECT 
    DISTINCT interest_id,
    interest_name,
    ROUND(CAST(STDDEV(percentile_ranking) OVER(PARTITION BY interest_id)AS NUMERIC),2) std_percentile_ranking
  FROM interest_met_temp imt
  JOIN interest_map map
  ON imt.interest_id = map.id
  ORDER BY std_percentile_ranking DESC
  LIMIT 5),
   
  cte2 AS (
SELECT
  cte.interest_id,
  interest_name,
  MIN(percentile_ranking) min_pct_rank
FROM cte
LEFT JOIN interest_met_temp imt ON cte.interest_id=imt.interest_id
GROUP BY 1,2)
  
  SELECT
    cte2.interest_id,
    cte2.interest_name,
    cte2.min_pct_rank,
    met.month_year
  INTO min_temp_tbl
  FROM cte2 
  LEFT JOIN interest_met_temp met ON cte2.interest_id=met.interest_id AND cte2.min_pct_rank=met.percentile_ranking;

  SELECT * FROM min_temp_tbl;
```

| interest_id | interest_name                          | min_pct_rank | month_year |
|-------------|----------------------------------------|--------------|------------|
| 10839	       | Tampa and St Petersburg Trip Planners  | 	4.84	         | 2019-03-01 |
| 43546	       | Personalized Gift Shoppers             | 	5.7	          | 2019-06-01 |
| 38992	       | Oregon Trip Planners                   | 	2.2	          | 2019-07-01 |
| 20764	       | Entertainment Industry Decision Makers | 	11.23	        | 2019-08-01 |
| 23	          | Techies                                | 	7.92	         | 2019-08-01 |

###### SQL

```TSQL
--Max
WITH cte AS (
  SELECT 
    DISTINCT interest_id,
    interest_name,
    ROUND(CAST(STDDEV(percentile_ranking) OVER(PARTITION BY interest_id)AS NUMERIC),2) std_percentile_ranking
  FROM interest_met_temp imt
  JOIN interest_map map
  ON imt.interest_id = map.id
  ORDER BY std_percentile_ranking DESC
  LIMIT 5),
   
  cte2 AS (
SELECT
  cte.interest_id,
  interest_name,
  MAX(percentile_ranking) max_pct_rank
FROM cte
LEFT JOIN interest_met_temp imt ON cte.interest_id=imt.interest_id
GROUP BY 1,2),
  
  cte3 AS 
  (SELECT
    cte2.interest_id,
    cte2.interest_name,
    cte2.max_pct_rank,
    met.month_year
  FROM cte2 
  LEFT JOIN interest_met_temp met ON cte2.interest_id=met.interest_id AND cte2.max_pct_rank=met.percentile_ranking)
  
  
--join tables

SELECT 
  mtt.interest_id,
  mtt.interest_name,
  map.interest_summary,
  mtt.min_pct_rank,
  mtt.month_year, 
  cte3.max_pct_rank, 
  cte3.month_year
FROM min_temp_tbl mtt
JOIN cte3 ON mtt.interest_id=cte3.interest_id
LEFT JOIN interest_map map ON mtt.interest_id=map.id;
```

###### Python

```python
merged_df = std_df.merge(removed_df, how='left', on='interest_id')

merged_df = merged_df.groupby(['interest_id', 'interest_name', 'interest_summary']).agg(min_pct_rnk=('percentile_ranking', 'min'),
                                                                                        max_pct_rnk=('percentile_ranking', 'max'))

merged_df = merged_df.merge(removed_df[['percentile_ranking', 'interest_id', 'month_year']], how='left', left_on=['interest_id', 'min_pct_rnk'], right_on=['interest_id', 'percentile_ranking'])
merged_df = merged_df.rename(columns={'month_year':'min_pct_rnk_month_year'})

merged_df = merged_df.merge(removed_df[['percentile_ranking', 'interest_id', 'month_year']], how='left', left_on=['interest_id', 'max_pct_rnk'], right_on=['interest_id', 'percentile_ranking'])
merged_df = merged_df.rename(columns={'month_year':'max_pct_rnk_month_year'})

merged_df = merged_df.merge(i_map, how='left', left_on='interest_id', right_on='id')
merged_df[['interest_id', 'interest_name', 'interest_summary', 'min_pct_rnk', 'min_pct_rnk_month_year', 'max_pct_rnk', 'max_pct_rnk_month_year']]
```

| interest_id | interest_name                          | interest_summary                                                                                                                                                        | min_pct_rank | month_year | max_pct_rank | month_year |
|-------------|----------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|------------|--------------|------------|
| 23	          | Techies                                | Readers of tech news and gadget reviews.                                                                                                                                | 	7.92	         | 2019-08-01 | 	86.69	        | 2018-07-01 |
| 20764	       | Entertainment Industry Decision Makers | Professionals reading industry news and researching trends in the entertainment industry.                                                                               | 	11.23	        | 2019-08-01 | 	86.15	        | 2018-07-01 |
| 10839	       | Tampa and St Petersburg Trip Planners  | People researching attractions and accommodations in Tampa and St Petersburg. These consumers are more likely to spend money on flights, hotels, and local attractions. | 	4.84	         | 2019-03-01 | 	75.03	        | 2018-07-01 |
| 38992	       | Oregon Trip Planners                   | People researching attractions and accommodations in Oregon. These consumers are more likely to spend money on travel and local attractions.                            | 	2.2	          | 2019-07-01 | 	82.44	        | 2018-11-01 |
| 43546	       | Personalized Gift Shoppers             | Consumers shopping for gifts that can be personalized.                                                                                                                  | 	5.7	          | 2019-06-01 | 	73.15	        | 2019-03-01 |

All 5 interests have pretty big ranges between minimum percentile rank and maximum percentile rank, which might mean those interests have seasonal demands.

