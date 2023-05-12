# 🍊 Case Study #8 - Fresh Segments

<p align="center">
<img src="https://github.com/KannaKit/8_Week_SQL_Challenge/assets/106714718/50e11374-422f-4399-bb47-4a2ff25d50d2" align="center" width="400" height="400" >

---
  
## 📑 Introduction
  
Danny created Fresh Segments, a digital marketing agency that helps other businesses analyse trends in online ad click behaviour for their unique customer base.

Clients share their customer lists with the Fresh Segments team who then aggregate interest metrics and generate a single dataset worth of metrics for further analysis.

In particular - the composition and rankings for different interests are provided for each client showing the proportion of their customer list who interacted with online assets related to each interest for each month.

Danny has asked for your assistance to analyse aggregated metrics for an example client and provide some high level insights about the customer list and their interests.
  
  ---
  
## ❔ Case Study Questions
  
The following questions can be considered key business questions that are required to be answered for the Fresh Segments team.

Most questions can be answered using a single query however some questions are more open ended and require additional thought and not just a coded solution!

  ---
  
### 🧼 Data Exploration and Cleansing

  1. Update the `fresh_segments.interest_metrics` table by modifying the `month_year` column to be a date data type with the start of the month
  2. What is count of records in the `fresh_segments.interest_metrics` for each `month_year` value sorted in chronological order (earliest to latest) with the null values appearing first?
  3. What do you think we should do with these null values in the `fresh_segments.interest_metrics`
  4. How many `interest_id` values exist in the `fresh_segments.interest_metrics` table but not in the `fresh_segments.interest_map` table? What about the other way around?
  5. Summarise the `id` values in the `fresh_segments.interest_map` by its total record count in this table
  6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where `interest_id = 21246` in your joined output and include all columns from `fresh_segments.interest_metrics` and all columns from `fresh_segments.interest_map` except from the `id` column.
  7. Are there any records in your joined table where the `month_year` value is before the `created_at` value from the `fresh_segments.interest_map` table? Do you think these values are valid and why?

▶️ **Check my solution [HERE](https://github.com/KannaKit/8_Week_SQL_Challenge/blob/main/Case%20Study%20%238%20-%20Fresh%20Segments/Data%20Exploration%20and%20Cleansing.md)** 
  
---
  
### 💹 Interest Analysis
  
  1. Which interests have been present in all `month_year` dates in our dataset?
  2. Using this same `total_months` measure - calculate the cumulative percentage of all records starting at 14 months - which `total_months` value passes the 90% cumulative percentage value?
  3. If we were to remove all `interest_id` values which are lower than the `total_months` value we found in the previous question - how many total data points would we be removing?
  4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed `interest` example for your arguments - think about what it means to have less months present from a segment perspective.
  5. After removing these interests - how many unique interests are there for each month?
  
▶️ **Check my solution [HERE](https://github.com/KannaKit/8_Week_SQL_Challenge/blob/main/Case%20Study%20%238%20-%20Fresh%20Segments/Interest%20Analysis.md)**   
  
---
  
### 👩‍💻 Segment Analysis

  1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any `month_year`? Only use the maximum composition value for each interest but you must keep the corresponding `month_year`
  2. Which 5 interests had the lowest average `ranking` value?
  3. Which 5 interests had the largest standard deviation in their `percentile_ranking` value?
  4. For the 5 interests found in the previous question - what was minimum and maximum `percentile_ranking` values for each interest and its corresponding `year_month` value? Can you describe what is happening for these 5 interests?

▶️ **Check my solution [HERE](https://github.com/KannaKit/8_Week_SQL_Challenge/blob/main/Case%20Study%20%238%20-%20Fresh%20Segments/Segment%20Analysis.md)**
  
---
  
## 👩‍💻 Data Visualization

<p align="center">
<img src="https://github.com/KannaKit/8_Week_SQL_Challenge/assets/106714718/b09eaf36-1f58-46d9-98ae-722694077816" align="center" width="1024" height="768">

▶️ **Check my Tableau dashboad [HERE](https://public.tableau.com/app/profile/kanna2901/viz/freshsegmentsinterestanalysis/Dashboard2?publish=yes)** 
