# 🍊 Case Study #8 - Fresh Segments
## 🧼 Data Exploration and Cleansing
### 1. Update the `fresh_segments.interest_metrics` table by modifying the `month_year` column to be a date data type with the start of the month

```TSQL
-- month_year column is varchar(7) so change data type so it can store more characters
ALTER TABLE interest_metrics
ALTER COLUMN month_year SET DATA TYPE TEXT;

-- change the order of data column and add '01' 
UPDATE interest_metrics
SET month_year = (CASE WHEN month_year IS NULL THEN NULL
                  ELSE SUBSTRING(month_year FROM 4) || '-' || SUBSTRING(month_year FROM 1 FOR 3) || '01' END);
                  
-- change data type to date
ALTER TABLE interest_metrics
ALTER COLUMN month_year SET DATA TYPE DATE USING month_year::DATE;
```

---

### 2. What is count of records in the `fresh_segments.interest_metrics` for each `month_year` value sorted in chronological order (earliest to latest) with the null values appearing first?

```TSQL
SELECT month_year, COUNT(*) record_count
FROM interest_metrics
GROUP BY month_year
ORDER BY 1 NULLS FIRST;
```

First 5 rows. 

| month_year | record_count |
|------------|--------------|
|  null          | 1194         |
| 2018-07-01 | 	729          |
| 2018-08-01 | 	767          |
| 2018-09-01 | 	780          |
| 2018-10-01 | 	857          |

---

### 3. What do you think we should do with these null values in the `fresh_segments.interest_metrics`

* I'd say drop rows with null month_year except 21246 interest_id.
* I can inpute median values to null cells but median value will be '2019-02-01' and all the 1193 rows will be added to one section and it'll be unbalanced.
* Without interest_id I can't add the 'interest_map' table so I'll drop all the rows with null interest_id.

```TSQL
DELETE FROM interest_metrics
WHERE interest_id IS NULL;
```

---

### 4. How many `interest_id` values exist in the `fresh_segments.interest_metrics` table but not in the `fresh_segments.interest_map` table? What about the other way around?

```TSQL
--change data type for interest_id column
ALTER TABLE interest_metrics
ALTER COLUMN interest_id SET DATA TYPE INT USING interest_id::INT;

SELECT 
  SUM(CASE WHEN interest_id IS NULL THEN 1 END) not_in_map,
  SUM(CASE WHEN map.id IS NULL THEN 1 END) not_in_met
FROM interest_metrics met
FULL JOIN interest_map map ON met.interest_id=map.id;
```

| not_in_map | not_in_met |
|-------------------------|-------------|
| 1200                  | 1193 |

---

### 5. Summarise the `id` values in the `fresh_segments.interest_map` by its total record count in this table

```TSQL
SELECT COUNT(*) id_count
FROM interest_map;
```

| id_count | 
|--------|
| 1209  | 

---

### 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where `interest_id = 21246` in your joined output and include all columns from `fresh_segments.interest_metrics` and all columns from `fresh_segments.interest_map` except from the `id` column.

`id` which don't exist in `interest_metrics` table are not relavent for this analysis so I used `LEFT JOIN`

```TSQL
SELECT
 met.*,
 interest_name,
 interest_summary,
 created_at,
 last_modified
FROM interest_metrics met
LEFT JOIN interest_map map ON met.interest_id=map.id
WHERE interest_id=21246;
```

First 5 rows.

| _month | _year | month_year | interest_id | composition | index_value | ranking | percentile_ranking | interest_name           |         interest_summary                                      | created_at          |   
|--------|-------|------------|-------------|-------------|-------------|---------|--------------------|----------------------------------|-------------------------------------------------------|---------------------|
| 7      | 2018  | 2018-07-01 | 	21246       | 2.26        | 0.65        | 722     | 0.96	               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 
| 8      | 2018  | 2018-08-01 | 	21246       | 2.13        | 0.59        | 765     | 0.26	               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 
| 9      | 2018  | 2018-09-01 | 	21246       | 2.06        | 0.61        | 774     | 0.77	               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 
| 10     | 2018  | 2018-10-01 | 	21246       | 1.74        | 0.58        | 855     | 0.23	               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 
| 11     | 2018  | 2018-11-01 | 	21246       | 2.25        | 0.78        | 908     | 2.16	               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 

---

### 7. Are there any records in your joined table where the `month_year` value is before the `created_at` value from the `fresh_segments.interest_map` table? Do you think these values are valid and why?

```TSQL
--check the number of data where the month_year value is before the created_at value
SELECT COUNT(*) AS count_before_created_at
FROM interest_metrics met
LEFT JOIN interest_map map ON met.interest_id=map.id
WHERE month_year < CAST(created_at AS DATE);
```

| count_before_created_at | 
|--------|
| 188  |

```TSQL
--check if they are on the same month
WITH cte AS (
SELECT *
FROM interest_metrics met
LEFT JOIN interest_map map ON met.interest_id=map.id
WHERE month_year < CAST(created_at AS DATE))

SELECT COUNT(*)
FROM cte
WHERE EXTRACT(MONTH FROM month_year) = EXTRACT(MONTH FROM (CAST(created_at AS DATE)));
```

| count | 
|--------|
| 188  |

All 188 rows with the created_at value are before the month_year value are on the same month.
Since month_year are set the first day of month, month_year column is not very specific.
I'll keep all 188 rows with the created_at value are before the month_year value.
