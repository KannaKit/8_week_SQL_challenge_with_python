# 🍊 Case Study #8 - Fresh Segments
## 💹 Interest Analysis
### 1. Which interests have been present in all `month_year` dates in our dataset?
###### SQL

```TSQL
--Find how many unique month_year dates in our dataset
WITH cte AS (
  SELECT COUNT(DISTINCT month_year) month_year_count
  FROM interest_metrics),

cte2 AS (
  SELECT 
    interest_id,
    COUNT(DISTINCT month_year) AS cnt
  FROM interest_metrics, cte
  GROUP BY interest_id, month_year_count
  HAVING COUNT(DISTINCT month_year) = month_year_count)

SELECT
  interest_id, interest_name, interest_summary
FROM cte2
LEFT JOIN interest_map map ON cte2.interest_id=map.id;
```

###### Python

```python
# Find how many unique month_year dates in our dataset
all_month = df['month_year'].nunique()

df2 = df[~df['month_year'].isna()]
df2 = df2.groupby('interest_id', as_index=False)['month_year'].nunique()

df2 = df2[df2['month_year']==all_month].merge(i_map, how='left', left_on='interest_id', right_on='id')

df2[['interest_id', 'interest_name', 'interest_summary']]
```

First 5 rows.

| interest_id | interest_name             | interest_summary                                                                   |
|-------------|---------------------------|------------------------------------------------------------------------------------|
| 4	           | Luxury Retail Researchers | Consumers researching luxury product reviews and gift ideas.                       |
| 5	           | Brides & Wedding Planners | People researching wedding ideas and vendors.                                      |
| 6	           | Vacation Planners         | Consumers reading reviews of vacation destinations and accommodations.             |
| 12	          | Thrift Store Shoppers     | Consumers shopping online for clothing at thrift stores and researching locations. |
| 15	          | NBA Fans                  | People reading articles and websites about basketball and the NBA.                 |

---

### 2. Using this same `total_months` measure - calculate the cumulative percentage of all records starting at 14 months - which `total_months` value passes the 90% cumulative percentage value?
###### SQL

```TSQL
WITH cte AS (
SELECT
  interest_id,
  COUNT(DISTINCT month_year) count_month_year
FROM interest_metrics
WHERE interest_id IS NOT NULL
GROUP BY interest_id),

cte2 AS (
SELECT
  count_month_year,
  COUNT(interest_id) interests
FROM cte
GROUP BY 1),

cte3 AS (
SELECT *,
       ROUND(SUM(interests) OVER (ORDER BY count_month_year DESC) / SUM(interests) OVER () *100.0 ,1) cumulative_pct
FROM cte2)

SELECT *
FROM cte3
WHERE cumulative_pct > 90.0;
```

###### Python

```python
df2 = df[~df['month_year'].isna()]
df2 = df2.groupby('interest_id')['month_year'].nunique().reset_index(name='count_month_year')

df2 = df2.groupby('count_month_year')['interest_id'].count().reset_index(name='interest_id_n')

total_int_id = sum(df2.interest_id_n)

df2['cumulative_sum'] = df2.loc[::-1, 'interest_id_n'].cumsum()[::-1]
df2['cumulative_pct'] = df2.cumulative_sum/total_int_id*100

df2[df2['cumulative_pct']>90]
```

| count_month_year | interests | cumulative_pct |
|------------------|-----------|----------------|
| 6                | 33        | 90.8           |
| 5                | 38        | 94             |
| 4                | 32        | 96.7           |
| 3                | 15        | 97.9           |
| 2                | 12        | 98.9           |
| 1                | 13        | 100            |

---

### 3. If we were to remove all `interest_id` values which are lower than the `total_months` value we found in the previous question - how many total data points would we be removing?
###### SQL

```TSQL
WITH cte AS (
SELECT
  interest_id,
  COUNT(DISTINCT month_year) count_month_year
FROM interest_metrics
WHERE interest_id IS NOT NULL
GROUP BY interest_id)

SELECT COUNT(DISTINCT interest_id) unique_interest_id_count, COUNT(interest_id) interest_id_count
FROM interest_metrics
WHERE interest_id IN (SELECT interest_id FROM cte WHERE count_month_year < 6);
```

###### Python

```python
df3 = df[~df['month_year'].isna()]
df3 = df3.groupby('interest_id')['month_year'].nunique().reset_index(name='count_month_year')

df3 = df3[df3['count_month_year']<6]

unique_id = df3.interest_id.nunique()

merged_df = df.merge(df3, how='right')
data_points = merged_df.interest_id.count()

print('Unique interest_id count:', unique_id)
print('Removing data points:', data_points)
```

| unique_interest_id_count | interest_id_count | 
|------------------|-----------|
| 110               | 400       | 

If we were to remove all `interest_id values` which are lower than the `total_months` value we found in the previous question, we would be removing 110 unique `interest_id`, and 400 data points.

---

### 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed `interest` example for your arguments - think about what it means to have less months present from a segment perspective.

* Removing data is not good from a business perspective because data is a valuable asset that can be used to make informed decisions. 
* Incomplete or inaccurate data can lead to incorrect conclusions and poor decision-making.

---

### 5. After removing these interests - how many unique interests are there for each month?
###### SQL

```TSQL
--Create a temporary table
SELECT *
INTO interest_met_temp
FROM interest_metrics
WHERE interest_id NOT IN (
  SELECT interest_id 
  FROM interest_metrics
  WHERE interest_id IS NOT NULL
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) < 6);
  
--Check the count of interests_id
SELECT
  COUNT(interest_id) interest_id_count,
  COUNT(DISTINCT interest_id) unique_interest_id_count
FROM interest_met_temp;

SELECT
  month_year,
  COUNT(DISTINCT interest_id) unique_interest_id_count
FROM interest_met_temp
WHERE month_year IS NOT NULL
GROUP BY 1
ORDER BY 1;
```

###### Python

```python
removed_df = df[~df['interest_id'].isin(df3.interest_id)]
removed_df.groupby('month_year')['interest_id'].nunique()
```

First 5 rows. 

| month_year | unique_interest_id_count |
|------------|--------------------------|
| 2018-07-01 | 	709                      |
| 2018-08-01 | 	752                      |
| 2018-09-01 | 	774                      |
| 2018-10-01 | 	853                      |
| 2018-11-01 | 	925                      |

